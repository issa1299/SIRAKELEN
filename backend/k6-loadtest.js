import http from 'k6/http';
import { check, sleep } from 'k6';

// Test de charge SIRA KELEN — LECTURE SEULE (sans danger pour la BDD).
// Usage : k6 run backend/k6-loadtest.js
// Cible : API cloud Render (offre gratuite -> rester leger !).

const BASE = __ENV.API_URL || 'https://sirakele-api.onrender.com';
// Passager reel possedant des compatibilites (matching v3).
const USER_ID = __ENV.USER_ID || '4f752bac-8703-4bea-ba9e-b53b85006841';

export const options = {
  stages: [
    { duration: '20s', target: 5 }, // montee a 5 utilisateurs
    { duration: '30s', target: 5 }, // palier
    { duration: '10s', target: 0 }, // descente
  ],
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<8000'],
  },
};

export default function () {
  // 1. Sante API
  let r = http.get(`${BASE}/`);
  check(r, { 'accueil 200': (x) => x.status === 200 });

  // 2. Moteur de matching (requete la plus couteuse)
  r = http.get(`${BASE}/ads/compatibilites/${USER_ID}`);
  check(r, { 'matching 200': (x) => x.status === 200 });

  // 3. Profil utilisateur
  r = http.get(`${BASE}/users/${USER_ID}`);
  check(r, { 'profil 200': (x) => x.status === 200 });

  sleep(1);
}
