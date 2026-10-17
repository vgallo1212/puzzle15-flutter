// Completa build/web/sw.js con la lista de archivos a guardar offline.
// Uso: node tool/pwa/generate_sw.js [build/web]
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const dir = path.resolve(process.argv[2] || 'build/web');
const swPath = path.join(dir, 'sw.js');

// No hace falta guardar mapas de depuracion ni los motores que esta
// version no usa (skwasm y wimp son solo para compilaciones --wasm).
// Si alguno se llegara a pedir, el sw lo guarda igual la primera vez.
const skip = (rel) =>
  rel === 'sw.js' ||
  rel === 'flutter_service_worker.js' ||
  rel.endsWith('.map') ||
  rel.endsWith('.symbols') ||
  rel.endsWith('.last_build_id') ||
  /^canvaskit\/(skwasm|wimp|webparagraph)/.test(rel);

function walk(current, out) {
  for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
    const full = path.join(current, entry.name);
    if (entry.isDirectory()) walk(full, out);
    else out.push(path.relative(dir, full).split(path.sep).join('/'));
  }
  return out;
}

const files = walk(dir, []).filter((f) => !skip(f)).sort();
const hash = crypto.createHash('sha256');
for (const f of files) hash.update(f).update(fs.readFileSync(path.join(dir, f)));
const version = hash.digest('hex').slice(0, 12);

// index.html se guarda como './' para que la navegacion offline lo encuentre.
const precache = ['./', ...files.filter((f) => f !== 'index.html')];

let sw = fs.readFileSync(swPath, 'utf8');
if (!sw.includes('__PRECACHE__')) {
  console.error('sw.js ya estaba generado o no tiene las marcas');
  process.exit(1);
}
sw = sw
  .replace('__VERSION__', version)
  .replace('__PRECACHE__', JSON.stringify(precache, null, 2));
fs.writeFileSync(swPath, sw);

console.log(`sw.js listo: version ${version}, ${precache.length} archivos en cache`);
