/**
 * Génère un Refresh Token OAuth2 pour l'envoi d'emails via Gmail API.
 *
 * PRÉREQUIS :
 *  1. Google Cloud Console > APIs & Services > Library > activer "Gmail API".
 *  2. APIs & Services > Credentials > OAuth client ID > type "Web application".
 *     - Authorized redirect URIs : http://localhost:4321/oauth2callback
 *  3. Renseigner GOOGLE_CLIENT_ID et GOOGLE_CLIENT_SECRET ci-dessous.
 *
 * UTILISATION :
 *  node scripts/get-gmail-refresh-token.js
 *  -> ouvre l'URL affichée, autorise, copie le code affiché dans le terminal.
 *  -> le script affiche le REFRESH_TOKEN à mettre dans .env sur Render.
 */

const http = require('http');
const { google } = require('googleapis');

const CLIENT_ID = process.env.GOOGLE_CLIENT_ID || 'VOTRE_CLIENT_ID';
const CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET || 'VOTRE_CLIENT_SECRET';
const REDIRECT_URI = 'http://localhost:4321/oauth2callback';
const SCOPES = ['https://www.googleapis.com/auth/gmail.send'];

const oauth2Client = new google.auth.OAuth2(CLIENT_ID, CLIENT_SECRET, REDIRECT_URI);

const authUrl = oauth2Client.generateAuthUrl({
  access_type: 'offline',
  scope: SCOPES,
  prompt: 'consent',
});

console.log('\n=== 1. Ouvre cette URL dans ton navigateur ===\n');
console.log(authUrl);
console.log('\n=== 2. Après autorisation, colle le code ici ===\n');

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const code = url.searchParams.get('code');
  if (code) {
    res.end('Autorisation reussie. Tu peux fermer cette fenetre et regarder le terminal.');
    server.close();
    oauth2Client.getToken(code).then(({ tokens }) => {
      console.log('\n=== 3. Ajoute ceci dans .env sur Render ===\n');
      console.log('GMAIL_REFRESH_TOKEN=' + tokens.refresh_token);
      console.log('GOOGLE_CLIENT_ID=' + CLIENT_ID);
      console.log('GOOGLE_CLIENT_SECRET=' + CLIENT_SECRET);
    }).catch((e) => console.error('Erreur:', e.message));
  } else {
    res.end('En attente du code...');
  }
});

server.listen(4321, () => console.log('Serveur d’attente sur http://localhost:4321'));

// Permettre aussi la saisie manuelle du code dans le terminal
process.stdin.setEncoding('utf8');
process.stdin.on('data', async (input) => {
  const code = input.trim();
  if (!code || code === 'VOTRE_CLIENT_ID') return;
  try {
    const { tokens } = await oauth2Client.getToken(code);
    console.log('\n=== Ajoute ceci dans .env sur Render ===\n');
    console.log('GMAIL_REFRESH_TOKEN=' + tokens.refresh_token);
    console.log('GOOGLE_CLIENT_ID=' + CLIENT_ID);
    console.log('GOOGLE_CLIENT_SECRET=' + CLIENT_SECRET);
  } catch (e) {
    console.error('Erreur:', e.message);
  }
});
