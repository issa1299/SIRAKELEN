import http from 'k6/http';
import { check, sleep } from 'k6';

// Test de charge 100 utilisateurs — LECTURE SEULE.
// Usage : k6 run backend/k6-charge-100.js
// Attention : offre gratuite Render/Supabase, seuils Elargis.

const BASE = __ENV.API_URL || 'https://sirakele-api.onrender.com';
const USER_ID = __ENV.USER_ID || '4f752bac-8703-4bea-ba9e-b53b85006841';

export const options = {
  stages: [
    { duration: '30s', target: 25 },
    { duration: '30s', target: 50 },
    { duration: '60s', target: 100 },
    { duration: '60s', target: 100 },
    { duration: '20s', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.15'],
    http_req_duration: ['p(95)<15000'],
  },
};

export default function () {
  let r = http.get(`${BASE}/`);
  check(r, { 'accueil 200': (x) => x.status === 200 });

  r = http.get(`${BASE}/ads/compatibilites/${USER_ID}`);
  check(r, { 'matching 200': (x) => x.status === 200 });

  r = http.get(`${BASE}/users/${USER_ID}`);
  check(r, { 'profil 200': (x) => x.status === 200 });

  sleep(1);
}
