/**
 * Chargement dynamique de la dernière version Android depuis le proxy Cloudflare.
 * Fichier séparé pour éviter le cache edge de index.html.
 */
(function () {
  const PROXY = 'https://sirakelen-api-proxy.diassanaissiaka68.workers.dev';

  function formatDateFr(iso) {
    if (!iso) return '—';
    const d = new Date(iso);
    if (isNaN(d.getTime())) return iso;
    const mois = ['janvier','février','mars','avril','mai','juin','juillet','août','septembre','octobre','novembre','décembre'];
    return d.getDate() + ' ' + mois[d.getMonth()] + ' ' + d.getFullYear();
  }

  // Expose globalement pour l'index
  window.SIRAKELEN_LATEST = null;

  fetch(PROXY + '/versions/latest?plateforme=android')
    .then(function (r) { return r.ok ? r.json() : null; })
    .then(function (v) {
      if (!v) return;
      window.SIRAKELEN_LATEST = v;
      // Mettre à jour les champs de la page si elle est déjà rendue
      var section = document.getElementById('downloadPageContent');
      if (section && typeof window.renderDownloadContent === 'function') {
        section.innerHTML = window.renderDownloadContent(v);
      }
      var footer = document.getElementById('footerVersion');
      if (footer) footer.textContent = 'Version ' + v.version + ' · Build ' + v.buildNumber;
    })
    .catch(function () {});

  window.formatDateFrSira = formatDateFr;
})();
