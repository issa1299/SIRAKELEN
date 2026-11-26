/**
 * Proxy API Cloudflare — relaie /api/* vers le backend NestJS.
 * Évite le CORS entre le site vitrine / l'admin et Render.
 * Relaie GET, POST, PATCH, DELETE avec le corps et les en-têtes utiles.
 */
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const cible = new URL(url.pathname.replace(/^\/api/, '') + url.search, env.BACKEND_URL);
    const method = request.method;

    const headers = { 'Accept': 'application/json' };
    const contentType = request.headers.get('content-type');
    if (contentType) headers['Content-Type'] = contentType;

    let body = undefined;
    if (method !== 'GET' && method !== 'HEAD') {
      body = await request.arrayBuffer();
    }

    const reponse = await fetch(cible.toString(), { method, headers, body });

    return new Response(reponse.body, {
      status: reponse.status,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,POST,PATCH,DELETE,OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Cache-Control': 'no-store',
      },
    });
  },
};
