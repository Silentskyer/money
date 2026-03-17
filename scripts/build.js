const fs = require("fs");
const path = require("path");

const projectRoot = path.resolve(__dirname, "..");
const distDir = path.join(projectRoot, "dist");

const filesToCopy = ["index.html", "styles.css", "app.js"];

const supabaseUrl = process.env.SUPABASE_URL || "";
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || "";

fs.rmSync(distDir, { recursive: true, force: true });
fs.mkdirSync(distDir, { recursive: true });

filesToCopy.forEach((file) => {
  fs.copyFileSync(path.join(projectRoot, file), path.join(distDir, file));
});

const config = `window.SUPABASE_CONFIG = {\n  url: "${supabaseUrl}",\n  anonKey: "${supabaseAnonKey}",\n};\n`;
fs.writeFileSync(path.join(distDir, "supabase-config.js"), config);

const setupPath = path.join(projectRoot, "SUPABASE_SETUP.md");
if (fs.existsSync(setupPath)) {
  fs.copyFileSync(setupPath, path.join(distDir, "SUPABASE_SETUP.md"));
}
