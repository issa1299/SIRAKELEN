/**
 * Proxy API : relaie /api/* vers le backend NestJS.
 * Le site vitrine appelle /api/versions/latest (même origine) → aucun CORS.
 * Seules les routes GET en lecture sont relayées (sécurité).
 */
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const cible = new URL(url.pathname.replace(/^\/api/, '') + url.search, env.BACKEND_URL);

    const reponse = await fetch(cible.toString(), {
      method: 'GET',
      headers: { 'Accept': 'application/json' },
    });

    return new Response(reponse.body, {
      status: reponse.status,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'public, max-age=60',
      },
    });
  },
};
