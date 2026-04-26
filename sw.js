const CACHE = 'mygarage-v1';
const FILES = ['/', '/index.html'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(FILES)));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(clients.claim());
});

self.addEventListener('fetch', e => {
  e.respondWith(
    caches.match(e.request).then(r => r || fetch(e.request))
  );
});

// Background sync for notifications
self.addEventListener('periodicsync', e => {
  if (e.tag === 'check-expiry') {
    e.waitUntil(checkAndNotify());
  }
});

self.addEventListener('push', e => {
  const data = e.data?.json() || {};
  e.waitUntil(
    self.registration.showNotification(data.title || 'MyGarage', {
      body: data.body || '',
      icon: '/icon-192.png',
      badge: '/icon-192.png',
    })
  );
});

async function checkAndNotify() {
  const clients_list = await clients.matchAll();
  if (clients_list.length > 0) return;

  // App is not open - check for expiring items
  // Data is stored in localStorage, access via client message
}
