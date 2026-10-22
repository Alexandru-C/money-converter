// Offline cache for the PWA. deploy_web.sh fills in VERSION and FILES after
// `flutter build web`; a new deploy changes VERSION, so the phone downloads
// the new files once and drops the old cache.
const VERSION = 'f8e637c227e2';
const FILES = ["assets/AssetManifest.bin","assets/AssetManifest.bin.json","assets/FontManifest.json","assets/NOTICES","assets/assets/fonts/Roboto-Medium.ttf","assets/assets/fonts/Roboto-Regular.ttf","assets/fonts/MaterialIcons-Regular.otf","assets/fonts/fallback/Roboto-Regular.ttf","assets/shaders/ink_sparkle.frag","assets/shaders/stretch_effect.frag","favicon.png","flutter.js","flutter_bootstrap.js","icons/Icon-192.png","icons/Icon-512.png","icons/Icon-maskable-192.png","icons/Icon-maskable-512.png","icons/apple-touch-icon.png","index.html","main.dart.js","manifest.json","version.json"];
const CACHE = 'converter-' + VERSION;

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE)
      .then((cache) => cache.addAll(['./', ...FILES]))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(
        keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// Cache first; anything not precached is fetched and stored for next time.
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  event.respondWith(
    caches.open(CACHE).then(async (cache) => {
      const hit = await cache.match(event.request, { ignoreSearch: true });
      if (hit) return hit;
      const res = await fetch(event.request);
      if (res.ok) cache.put(event.request, res.clone());
      return res;
    })
  );
});
