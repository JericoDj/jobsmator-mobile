import fs from 'fs';
const path = '/Volumes/External 1TB/Projects/n8n/workflows/jobsmator.json';
let data = fs.readFileSync(path, 'utf8');

// The sed command inserted a literal newline instead of a \n string literal.
// Let's find the broken string and fix it.
// The broken string is:
// const allSorted = scored.sort((a, b) => b.score - a.score || String(b.postedAt || "").localeCompare(String(a.postedAt || "")));
// const jobs = allSorted.map((j, rank) => ({

data = data.replace('const allSorted = scored.sort((a, b) => b.score - a.score || String(b.postedAt || "").localeCompare(String(a.postedAt || "")));\nconst jobs = allSorted.map((j, rank) => ({', 'const allSorted = scored.sort((a, b) => b.score - a.score || String(b.postedAt || \\"\\").localeCompare(String(a.postedAt || \\"\\")));\\nconst jobs = allSorted.map((j, rank) => ({');

try {
  JSON.parse(data);
  fs.writeFileSync(path, data);
  console.log("JSON fixed successfully!");
} catch (e) {
  console.error("Still invalid:", e.message);
  
  // Try another approach if the above replace didn't match
  data = data.replace(/\nconst jobs = allSorted/g, '\\nconst jobs = allSorted');
  data = data.replace(/""/g, '\\"\\"');
  
  try {
    JSON.parse(data);
    fs.writeFileSync(path, data);
    console.log("JSON fixed successfully on second try!");
  } catch (err) {
    console.error("Failed again:", err.message);
  }
}
