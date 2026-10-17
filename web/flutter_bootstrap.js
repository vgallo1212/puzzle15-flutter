{{flutter_js}}
{{flutter_build_config}}

// Sin serviceWorkerSettings: el service worker de Flutter esta obsoleto
// (solo se desregistra). La cache offline la maneja web/sw.js.
_flutter.loader.load();
