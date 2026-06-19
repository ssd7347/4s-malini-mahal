// Resolve the backend API base URL at runtime, independent of the build's
// environment label. During development the Ember dev server runs on :4200
// while the Java/Tomcat backend runs on :8080 under the /malinimahal context.
// In any other case we assume the frontend is served from the same origin as
// the backend and use relative URLs.
export function apiUrl(path) {
  const onDevServer =
    typeof window !== 'undefined' && window.location.port === '4200';
  const base = onDevServer ? 'http://localhost:8080/malinimahal' : '/malinimahal';
  return `${base}${path}`;
}
