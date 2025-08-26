self.addEventListener('push', (event) => {
  if (!event.data) {
    return;
  }
  const payload = event.data.json();
  const title = payload.notification && payload.notification.title ? payload.notification.title : 'BlueBubbles';
  const options = {
    body: payload.notification && payload.notification.body ? payload.notification.body : undefined,
    icon: payload.notification && payload.notification.icon ? payload.notification.icon : '/icons/Icon-192.png',
    data: payload.data || {}
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(self.clients.matchAll({type: 'window'}).then((clientList) => {
    for (const client of clientList) {
      if (client.url === '/' && 'focus' in client) {
        return client.focus();
      }
    }
    if (self.clients.openWindow) {
      return self.clients.openWindow('/');
    }
  }));
});
