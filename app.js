window.__APP_LOADED__ = true;
const APP_VERSION = "20260317-6";
const STORAGE_KEY = "ghibli-budget-entries";
const CLIENT_ID_KEY = "ghibli-budget-client-id";
const SUPABASE_TABLE = "entries";

const getClientId = () => {
  let id = localStorage.getItem(CLIENT_ID_KEY);
  if (!id) {
    id = crypto.randomUUID();
    localStorage.setItem(CLIENT_ID_KEY, id);
  }
  return id;
};

const supabaseConfig = window.SUPABASE_CONFIG || {};
const supabaseAvailable = Boolean(
  window.supabase && supabaseConfig.url && supabaseConfig.anonKey
);
const supabaseClient = supabaseAvailable
  ? window.supabase.createClient(supabaseConfig.url, supabaseConfig.anonKey)
  : null;

const form = document.getElementById("entry-form");
const itemInput = document.getElementById("item-input");
const amountInput = document.getElementById("amount-input");
const timeInput = document.getElementById("time-input");
const yearFilter = document.getElementById("year-filter");
const monthFilter = document.getElementById("month-filter");
const queryInput = document.getElementById("query-input");
const sortFilter = document.getElementById("sort-filter");
const entryList = document.getElementById("entry-list");
const clearBtn = document.getElementById("clear-btn");
const statusEl = document.getElementById("status");

const overallBalanceEl = document.getElementById("overall-balance");
const periodBalanceEl = document.getElementById("period-balance");
const periodBalanceEl2 = document.getElementById("period-balance-2");
const periodIncomeEl = document.getElementById("period-income");
const periodExpenseEl = document.getElementById("period-expense");

const setStatus = (message, level = "info") => {
  if (!statusEl) return;
  statusEl.textContent = message;
  statusEl.className = `status visible ${level}`;
};

const clearStatus = () => {
  if (!statusEl) return;
  statusEl.textContent = "";
  statusEl.className = "status";
};

const formatCurrency = (value) =>
  `NT$ ${value.toLocaleString("zh-Hant", { maximumFractionDigits: 0 })}`;

const formatDate = (iso) => {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return "Invalid date";
  return date.toLocaleString("zh-TW", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
};

const loadEntriesFromLocal = () => {
  const raw = localStorage.getItem(STORAGE_KEY);
  return raw ? JSON.parse(raw) : [];
};

const saveEntriesToLocal = (entries) => {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(entries));
};

const createLocalStore = () => ({
  async list() {
    return loadEntriesFromLocal();
  },
  async insert(entry) {
    const entries = loadEntriesFromLocal();
    entries.unshift(entry);
    saveEntriesToLocal(entries);
    return entry;
  },
  async remove(id) {
    const entries = loadEntriesFromLocal();
    const next = entries.filter((item) => item.id !== id);
    saveEntriesToLocal(next);
  },
  async clear() {
    saveEntriesToLocal([]);
  },
});

const createSupabaseStore = (client) => {
  const clientId = getClientId();
  return {
    async list() {
      const { data, error } = await client
        .from(SUPABASE_TABLE)
        .select("id,item,amount,type,time")
        .eq("client_id", clientId)
        .order("time", { ascending: false });
      if (error) {
        console.error("Supabase list error:", error);
        setStatus(`Supabase read failed: ${error.message}`, "error");
        return [];
      }
      clearStatus();
      return (data || []).map((row) => ({
        ...row,
        amount: Number(row.amount),
      }));
    },
    async insert(entry) {
      const payload = { ...entry, client_id: clientId };
      const { error } = await client.from(SUPABASE_TABLE).insert(payload);
      if (error) {
        console.error("Supabase insert error:", error);
        setStatus(`Supabase save failed: ${error.message}`, "error");
      } else {
        clearStatus();
      }
      return entry;
    },
    async remove(id) {
      const { error } = await client
        .from(SUPABASE_TABLE)
        .delete()
        .eq("id", id)
        .eq("client_id", clientId);
      if (error) {
        console.error("Supabase delete error:", error);
        setStatus(`Supabase delete failed: ${error.message}`, "error");
      } else {
        clearStatus();
      }
    },
    async clear() {
      const { error } = await client
        .from(SUPABASE_TABLE)
        .delete()
        .eq("client_id", clientId);
      if (error) {
        console.error("Supabase clear error:", error);
        setStatus(`Supabase clear failed: ${error.message}`, "error");
      } else {
        clearStatus();
      }
    },
  };
};

const store = supabaseClient ? createSupabaseStore(supabaseClient) : createLocalStore();

if (supabaseClient) {
  setStatus(`Supabase connected (v${APP_VERSION}), loading data.`, "success");
} else {
  setStatus(`Using local storage (v${APP_VERSION}), Supabase not connected.`, "info");
}

const getNowLocalInput = () => {
  const now = new Date();
  const offsetMs = now.getTimezoneOffset() * 60000;
  const local = new Date(now.getTime() - offsetMs);
  return local.toISOString().slice(0, 16);
};

const parseFilters = () => ({
  year: yearFilter.value,
  month: monthFilter.value,
  query: queryInput.value.trim().toLowerCase(),
  sort: sortFilter.value,
});

const ensureFilterOptions = (entries) => {
  const years = new Set(entries.map((entry) => new Date(entry.time).getFullYear()));
  const sortedYears = Array.from(years).filter((y) => !Number.isNaN(y)).sort((a, b) => b - a);

  const buildSelect = (selectEl, options, placeholder) => {
    const current = selectEl.value;
    selectEl.innerHTML = "";
    const allOption = document.createElement("option");
    allOption.value = "all";
    allOption.textContent = placeholder;
    selectEl.appendChild(allOption);
    options.forEach((value) => {
      const option = document.createElement("option");
      option.value = String(value);
      option.textContent = String(value);
      selectEl.appendChild(option);
    });
    if (current && Array.from(selectEl.options).some((opt) => opt.value === current)) {
      selectEl.value = current;
    }
  };

  buildSelect(yearFilter, sortedYears, "All years");

  const months = Array.from({ length: 12 }, (_, index) => index + 1);
  buildSelect(monthFilter, months.map((m) => String(m).padStart(2, "0")), "All months");
};

const computeTotals = (entries) => {
  return entries.reduce(
    (acc, entry) => {
      if (entry.type === "income") acc.income += entry.amount;
      if (entry.type === "expense") acc.expense += entry.amount;
      acc.balance = acc.income - acc.expense;
      return acc;
    },
    { income: 0, expense: 0, balance: 0 }
  );
};

const applyFilters = (entries, filters) => {
  return entries
    .filter((entry) => {
      if (filters.query && !entry.item.toLowerCase().includes(filters.query)) return false;
      const date = new Date(entry.time);
      if (filters.year !== "all" && date.getFullYear() !== Number(filters.year)) return false;
      if (filters.month !== "all") {
        const month = String(date.getMonth() + 1).padStart(2, "0");
        if (month !== filters.month) return false;
      }
      return true;
    })
    .sort((a, b) => {
      switch (filters.sort) {
        case "time_asc":
          return new Date(a.time) - new Date(b.time);
        case "item_asc":
          return a.item.localeCompare(b.item, "zh-Hant");
        case "item_desc":
          return b.item.localeCompare(a.item, "zh-Hant");
        default:
          return new Date(b.time) - new Date(a.time);
      }
    });
};

const renderEntries = (entries) => {
  entryList.innerHTML = "";
  if (entries.length === 0) {
    const empty = document.createElement("p");
    empty.textContent = "No entries yet.";
    empty.className = "entry-meta";
    entryList.appendChild(empty);
    return;
  }

  entries.forEach((entry) => {
    const card = document.createElement("div");
    card.className = "entry";

    const info = document.createElement("div");
    info.className = "entry-info";

    const title = document.createElement("div");
    title.className = "entry-title";
    title.textContent = entry.item;

    const meta = document.createElement("div");
    meta.className = "entry-meta";
    meta.innerHTML = `<span class="badge ${entry.type === "expense" ? "expense" : ""}">
      ${entry.type === "income" ? "Income" : "Expense"}
    </span> ${formatDate(entry.time)}`;

    info.appendChild(title);
    info.appendChild(meta);

    const actions = document.createElement("div");
    actions.className = "entry-actions";

    const amount = document.createElement("div");
    amount.className = "entry-amount";
    amount.textContent = formatCurrency(entry.amount);

    const del = document.createElement("button");
    del.className = "ghost";
    del.textContent = "Delete";
    del.addEventListener("click", async () => {
      await store.remove(entry.id);
      await refresh();
    });

    actions.appendChild(amount);
    actions.appendChild(del);

    card.appendChild(info);
    card.appendChild(actions);
    entryList.appendChild(card);
  });
};

const refresh = async () => {
  const entries = await store.list();
  ensureFilterOptions(entries);

  const overall = computeTotals(entries);
  overallBalanceEl.textContent = formatCurrency(overall.balance);

  const filters = parseFilters();
  const filtered = applyFilters(entries, filters);
  const period = computeTotals(filtered);

  periodBalanceEl.textContent = formatCurrency(period.balance);
  periodBalanceEl2.textContent = formatCurrency(period.balance);
  periodIncomeEl.textContent = formatCurrency(period.income);
  periodExpenseEl.textContent = formatCurrency(period.expense);

  renderEntries(filtered);
};

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  const item = itemInput.value.trim();
  const amount = Number(amountInput.value);
  const type = form.elements.type.value;
  const time = timeInput.value ? new Date(timeInput.value).toISOString() : new Date().toISOString();

  if (!item || Number.isNaN(amount) || amount <= 0) {
    return;
  }

  const entry = {
    id: crypto.randomUUID(),
    item,
    amount,
    type,
    time,
  };
  await store.insert(entry);
  form.reset();
  timeInput.value = getNowLocalInput();
  await refresh();
});

[yearFilter, monthFilter, queryInput, sortFilter].forEach((el) => {
  el.addEventListener("input", () => {
    void refresh();
  });
});

clearBtn.addEventListener("click", async () => {
  if (!confirm("Are you sure you want to clear all entries?")) return;
  await store.clear();
  await refresh();
});

timeInput.value = getNowLocalInput();
void refresh();
