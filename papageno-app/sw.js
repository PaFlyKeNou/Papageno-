// Papageno · le service worker garde la boutique ouverte, même sans réseau.
// À chaque mise à jour du site, change VERSION pour que les téléphones récupèrent la nouvelle version.
const VERSION = 'papageno-v10';
const FONTS = 'papageno-polices';
const CORE = ['./', 'index.html', 'manifest.webmanifest', 'vendor/matter.min.js', 'bienvenue.mp3', 'aurevoir.mp3',
  'icons/icon-192.png', 'icons/icon-512.png', 'icons/icon-maskable-512.png', 'icons/apple-touch-icon.png', 'icons/favicon-32.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(VERSION).then(c => c.addAll(CORE)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys()
    .then(keys => Promise.all(keys.filter(k => k !== VERSION && k !== FONTS).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});
self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET' || req.headers.has('range')) return;   // les lectures audio par morceaux passent par le réseau
  const url = new URL(req.url);
  if (url.pathname.includes('/musique/')) return;                   // la playlist se joue depuis internet (on ne remplit pas le téléphone de musique)
  // la page : le réseau d'abord (pour avoir la dernière version), sinon la copie gardée
  if (req.mode === 'navigate') {
    e.respondWith(fetch(req).then(r => { const copy = r.clone(); caches.open(VERSION).then(c => c.put('index.html', copy)); return r; })
      .catch(() => caches.match('index.html')));
    return;
  }
  // les polices Google : la copie gardée tout de suite, mise à jour en arrière-plan
  if (/^fonts\.(googleapis|gstatic)\.com$/.test(url.hostname)) {
    e.respondWith(caches.open(FONTS).then(async c => {
      const hit = await c.match(req);
      const net = fetch(req).then(r => { if (r.ok || r.type === 'opaque') c.put(req, r.clone()); return r; }).catch(() => hit);
      return hit || net;
    }));
    return;
  }
  // le reste du site : la copie gardée d'abord, sinon le réseau
  if (url.origin === self.location.origin) {
    e.respondWith(caches.match(req).then(hit => hit || fetch(req).then(r => {
      if (r.ok) { const copy = r.clone(); caches.open(VERSION).then(c => c.put(req, copy)); }
      return r;
    })));
  }
});
