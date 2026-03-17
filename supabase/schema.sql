create table if not exists public.entries (
  id uuid primary key,
  client_id uuid not null,
  item text not null,
  amount integer not null check (amount > 0),
  type text not null check (type in ('income', 'expense')),
  time timestamptz not null
);

alter table public.entries enable row level security;

create policy "public read" on public.entries
for select using (true);

create policy "public insert" on public.entries
for insert with check (true);

create policy "public update" on public.entries
for update using (true) with check (true);

create policy "public delete" on public.entries
for delete using (true);
