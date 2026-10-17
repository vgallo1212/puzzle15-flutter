// Verifica que la version web siga siendo una PWA instalable y offline.
//
// 1. Revisa manifest, iconos, registro del service worker y lista de cache.
// 2. Si hay Chrome (variable CHROME_PATH) abre la app en modo headless,
//    espera al service worker, corta la red y recarga: la app debe volver
//    a arrancar sin conexion.
//
// Uso: node tool/pwa/check_pwa.js build/web /nombre-repo/
const fs = require('fs');
const http = require('http');
const path = require('path');

const dir = path.resolve(process.argv[2] || 'build/web');
const base = process.argv[3] || '/';
const errors = [];
const check = (ok, msg) => {
  console.log(`${ok ? 'OK ' : 'ERR'}  ${msg}`);
  if (!ok) errors.push(msg);
};

function staticChecks() {
  const manifest = JSON.parse(fs.readFileSync(path.join(dir, 'manifest.json'), 'utf8'));
  check(!!manifest.name && !!manifest.short_name, 'manifest tiene name y short_name');
  check(!!manifest.start_url, 'manifest tiene start_url');
  check(['standalone', 'fullscreen', 'minimal-ui'].includes(manifest.display),
    `manifest display = ${manifest.display}`);
  for (const size of ['192x192', '512x512']) {
    const icon = (manifest.icons || []).find((i) => i.sizes === size);
    check(!!icon && fs.existsSync(path.join(dir, icon.src)), `icono ${size} existe`);
  }
  check((manifest.icons || []).some((i) => i.purpose === 'maskable'), 'hay icono maskable');

  const index = fs.readFileSync(path.join(dir, 'index.html'), 'utf8');
  check(index.includes('rel="manifest"'), 'index.html enlaza el manifest');
  check(index.includes("serviceWorker.register('sw.js')"), 'index.html registra sw.js');
  check(index.includes(`<base href="${base}">`), `base href = ${base}`);

  const sw = fs.readFileSync(path.join(dir, 'sw.js'), 'utf8');
  check(!sw.includes('__PRECACHE__'), 'sw.js tiene la lista de cache generada');
  for (const f of ['main.dart.js', 'flutter_bootstrap.js', 'canvaskit/canvaskit.wasm']) {
    check(sw.includes(`"${f}"`), `sw.js guarda ${f}`);
  }
  check(!index.includes('gstatic.com') && !fs.readFileSync(path.join(dir, 'flutter_bootstrap.js'), 'utf8').includes('"useLocalCanvasKit":false'),
    'CanvasKit se sirve desde la propia app (no desde el CDN)');
}

const types = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png',
  '.ttf': 'font/ttf', '.otf': 'font/otf', '.css': 'text/css', '.bin': 'application/octet-stream',
};

function serve() {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      let url = decodeURIComponent(req.url.split('?')[0]);
      if (!url.startsWith(base)) { res.writeHead(404); return res.end(); }
      let file = path.join(dir, url.slice(base.length));
      if (!file.startsWith(dir)) { res.writeHead(403); return res.end(); }
      if (fs.existsSync(file) && fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
      if (!fs.existsSync(file)) { res.writeHead(404); return res.end(); }
      res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream' });
      fs.createReadStream(file).pipe(res);
    });
    server.listen(0, '127.0.0.1', () => resolve(server));
  });
}

async function offlineCheck() {
  const chrome = process.env.CHROME_PATH;
  if (!chrome) {
    console.log('--   Sin CHROME_PATH: se omite la prueba offline en navegador');
    return;
  }
  const puppeteer = require('puppeteer-core');
  const server = await serve();
  const url = `http://127.0.0.1:${server.address().port}${base}`;
  const browser = await puppeteer.launch({ executablePath: chrome, headless: true, args: ['--no-sandbox'] });
  try {
    const page = await browser.newPage();
    await page.goto(url, { waitUntil: 'load' });
    await page.waitForSelector('flutter-view', { timeout: 60000 });
    check(true, 'la app arranca con conexion');

    const ready = await page.evaluate(async () => {
      const reg = await navigator.serviceWorker.ready;
      return !!reg.active;
    });
    check(ready, 'service worker activo');

    // Espera a que termine de guardar todo antes de cortar la red.
    await page.waitForFunction(async () => {
      const keys = await caches.keys();
      return keys.some((k) => k.startsWith('puzzle15-')) && navigator.serviceWorker.controller;
    }, { timeout: 60000, polling: 500 });
    await page.reload({ waitUntil: 'load' });

    await page.setOfflineMode(true);
    await page.reload({ waitUntil: 'load' });
    await page.waitForSelector('flutter-view', { timeout: 60000 });
    const failed = await page.evaluate(() => document.title);
    check(failed.includes('15-Puzzle'), 'sin conexion la app vuelve a cargar');
  } catch (err) {
    check(false, `prueba offline: ${err.message}`);
  } finally {
    await browser.close();
    server.close();
  }
}

(async () => {
  staticChecks();
  await offlineCheck();
  if (errors.length) {
    console.error(`\n${errors.length} comprobaciones fallaron`);
    process.exit(1);
  }
  console.log('\nLa app sigue siendo una PWA instalable y offline');
})();
