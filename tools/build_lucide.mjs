// Rebuilds icons/lucide.json from a local lucide npm package (1.x).
// Stores each icon's inner SVG markup; core/wold_icons.gd wraps and renders it.
//
//   node tools/build_lucide.mjs <path to node_modules/lucide-react>
//
// names sorted, so same version in -> same bytes out
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const pkgDir = process.argv[2];
if (!pkgDir) {
  console.error('usage: node tools/build_lucide.mjs <path to lucide-react>');
  process.exit(1);
}
const repo = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const pkg = JSON.parse(fs.readFileSync(path.join(pkgDir, 'package.json'), 'utf8'));
const iconDir = path.join(pkgDir, 'dist', 'esm', 'icons');

const escape = (v) => String(v).replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;');
const icons = {};
for (const file of fs.readdirSync(iconDir).filter((f) => f.endsWith('.mjs')).sort()) {
  const text = fs.readFileSync(path.join(iconDir, file), 'utf8');
  const match = text.match(/const __iconData = (\{[\s\S]*?\n\});/);
  if (!match) continue; // alias modules re-export a canonical icon
  const data = new Function(`return (${match[1]});`)();
  if (data.size !== 24) throw new Error(`${file}: expected a 24px grid, got ${data.size}`);
  icons[data.name] = data.node
    .map(([tag, attrs]) => {
      const list = Object.entries(attrs)
        .filter(([k]) => k !== 'key')
        .map(([k, v]) => `${k}="${escape(v)}"`)
        .join(' ');
      return `<${tag} ${list}/>`;
    })
    .join('');
}

const names = Object.keys(icons).sort();
const out = { source: 'lucide', version: pkg.version, license: 'ISC', grid: 24, icons: {} };
for (const n of names) out.icons[n] = icons[n];

fs.mkdirSync(path.join(repo, 'icons'), { recursive: true });
fs.writeFileSync(path.join(repo, 'icons', 'lucide.json'), JSON.stringify(out, null, 0) + '\n');
fs.copyFileSync(path.join(pkgDir, 'LICENSE'), path.join(repo, 'icons', 'LICENSE-lucide.txt'));
console.log(`lucide ${pkg.version}: ${names.length} icons -> icons/lucide.json`);
