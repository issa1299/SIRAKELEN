/**
 * Proxy API Cloudflare — relaie /api/* vers le backend NestJS.
 * Évite le CORS entre le site vitrine / l'admin et Render.
 * Relaie GET, POST, PATCH, DELETE avec corps, Authorization et prévol OPTIONS.
 */
const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,POST,PATCH,DELETE,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Cache-Control': 'no-store',
};

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS });
    }

    const url = new URL(request.url);
    const cible = new URL(
      url.pathname.replace(/^\/api/, '') + url.search,
      env.BACKEND_URL,
    );

    const headers = { Accept: 'application/json' };
    const contentType = request.headers.get('content-type');
    if (contentType) headers['Content-Type'] = contentType;
    const authorization = request.headers.get('authorization');
    if (authorization) headers['Authorization'] = authorization;

    let body;
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      body = await request.arrayBuffer();
    }

    const reponse = await fetch(cible.toString(), {
      method: request.method,
      headers,
      body,
    });

    return new Response(reponse.body, {
      status: reponse.status,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        ...CORS,
      },
    });
  },
};
