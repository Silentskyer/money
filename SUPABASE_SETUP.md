# Supabase Setup

This project can use Supabase when you deploy, and fall back to `localStorage` when the config is empty.

## 1) Create schema
1. Open Supabase SQL editor.
2. Run the SQL in `supabase/schema.sql`.

## 2) Configure client (local)
1. Copy your project URL and anon key from Supabase Project Settings.
2. Fill them into `supabase-config.js`:

```js
window.SUPABASE_CONFIG = {
  url: "https://YOUR_PROJECT.supabase.co",
  anonKey: "YOUR_ANON_KEY",
};
```

If both values are empty, the app stays on `localStorage`.

## 3) Configure client (Vercel)
Set these environment variables in Vercel Project Settings:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

The build step will inject them into `dist/supabase-config.js`.

## 4) Security note
This demo does not use authentication. The provided policy allows public read/write on the table.
For production, add Supabase Auth and change RLS policies to protect each user¡¦s data.
