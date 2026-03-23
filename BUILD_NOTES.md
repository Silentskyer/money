# 專案建置與完成筆記

日期：2026-03-17

## 專案概述
這是一個前端記帳工具，支援本機 `localStorage`，並可在部署時切換為 Supabase 作為資料庫。

## 建置與部署流程
1. 本機開發完成前端頁面
2. 加入 Supabase 可選資料層（不填設定時仍使用 `localStorage`）
3. 加入 Vercel 部署流程
4. 設定 Supabase 資料表與 RLS 政策
5. 上傳 GitHub，觸發 Vercel 自動部署

## 主要檔案與用途
- `index.html`：頁面結構與表單
- `styles.css`：視覺樣式
- `app.js`：記帳邏輯、篩選、儲存、讀取
- `supabase/schema.sql`：Supabase 資料表與 RLS 規則
- `supabase-config.js`：Supabase 前端設定（本機用，部署用環境變數注入）
- `scripts/build.js`：Vercel build 時注入 `SUPABASE_URL` 與 `SUPABASE_ANON_KEY`
- `vercel.json`：Vercel build 與輸出設定
- `SUPABASE_SETUP.md`：Supabase 設定步驟

## Supabase 設定步驟
1. 進入 Supabase SQL Editor
2. 執行 `supabase/schema.sql`
3. 確認 `entries` 表存在
4. 確認 RLS 已啟用且有政策（允許存取）

## Vercel 設定步驟
1. 匯入 GitHub 專案
2. 設定環境變數：
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
3. 重新部署

## 建立一筆記帳的完整流程
1. 開啟網站
2. 輸入：
   - 項目
   - 金額
   - 類型（收入/支出）
   - 時間
3. 點擊「加入清單」
4. 系統流程：
   - 前端產生 `id` 與時間戳
   - 若 Supabase 已設定：寫入 `entries` 表
   - 否則寫入 `localStorage`
5. 重新整理清單顯示在畫面

## 常見問題排除摘要
- 若頁面顯示「JavaScript 尚未載入或發生錯誤」：
  - 檢查 `app.js` 是否成功載入
  - 確認 `index.html` 引用的 `app.js?v=...` 是最新
- 若 Supabase 沒有資料寫入：
  - 確認 `SUPABASE_URL` / `SUPABASE_ANON_KEY` 是否正確
  - 檢查 RLS 政策是否允許 insert
- 若清單不顯示：
  - 檢查 Console 是否有語法錯誤

## 最終狀態
- 前端頁面完成
- 可使用本機儲存或 Supabase
- 已可透過 Vercel 部署
