const CACHE_NAME = "teachable-pokedex-v1";
const APP_SHELL = [
  "./",
  "./index.html",
  "./vr.html",
  "./manifest.json",
  "./assets/css/main.css",
  "./assets/js/alpine.js",
  "./assets/js/pokedex_ui.js",
  "./assets/js/pokedex_ml.js",
  "./assets/js/pokedex_speech.js",
  "./assets/js/pokedex_sound.js",
  "./assets/js/vr.js",
  "./assets/rive/pokedex.riv",
  "./assets/my_model/model.json",
  "./assets/my_model/metadata.json",
  "./assets/my_model/weights.bin",
  "./assets/icons/icon.png",
  "./assets/img/background.png",
  "./assets/sounds/SFX_PRESS_AB.wav",
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL)),
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((cacheNames) =>
        Promise.all(
          cacheNames
            .filter((cacheName) => cacheName !== CACHE_NAME)
            .map((cacheName) => caches.delete(cacheName)),
        ),
      ),
  );
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") {
    return;
  }

  event.respondWith(
    caches.match(event.request).then((cached) => {
      if (cached) {
        return cached;
      }

      return fetch(event.request)
        .then((response) => {
          if (
            !response ||
            response.status !== 200 ||
            response.type !== "basic"
          ) {
            return response;
          }

          const responseClone = response.clone();
          caches
            .open(CACHE_NAME)
            .then((cache) => cache.put(event.request, responseClone));
          return response;
        })
        .catch(() => caches.match("./index.html"));
    }),
  );
});
