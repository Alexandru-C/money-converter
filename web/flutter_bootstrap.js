{{flutter_js}}
{{flutter_build_config}}

// No serviceWorkerSettings: Flutter's own service worker would replace sw.js
// (same scope) and then unregister itself. Offline caching is done by sw.js.
_flutter.loader.load();
