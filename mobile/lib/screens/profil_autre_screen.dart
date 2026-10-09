import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/api_service.dart';

class ProfilAutreScreen extends StatefulWidget {
  final String targetUserId;
  final String viewerUserId;
  const ProfilAutreScreen({
    super.key,
    required this.targetUserId,
    required this.viewerUserId,
  });

  @override
  State<ProfilAutreScreen> createState() => _ProfilAutreScreenState();
}

class _ProfilAutreScreenState extends State<ProfilAutreScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic> _stats = {
    'adPublies': 0,
    'trajetsOrganises': 0,
    'signalements': 0
  };
  List<dynamic> _trajets = [];
  bool _chargement = true;
  bool _contactDebloque = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final user = await ApiService.getUser(widget.targetUserId);
      final stats = await ApiService.getStats(widget.targetUserId);
      final trajets = await ApiService.getTrajetsPublics(widget.targetUserId);
      // Contact visible uniquement si une demande acceptee lie les deux.
      bool debloque = false;
      try {
        final recuesCible = await ApiService.getDemandesRecues(widget.targetUserId);
        debloque = recuesCible.any((d) =>
            (d['demandeur']?['id'] as String? ?? '') == widget.viewerUserId &&
            d['statut'] == 'acceptee');
        if (!debloque) {
          final recuesMoi = await ApiService.getDemandesRecues(widget.viewerUserId);
          debloque = recuesMoi.any((d) =>
              (d['demandeur']?['id'] as String? ?? '') == widget.targetUserId &&
              d['statut'] == 'acceptee');
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _user = user;
        _stats = stats;
        _trajets = trajets;
        _contactDebloque = debloque;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  Future<void> _appeler(String tel) async {
    final uri = Uri(scheme: 'tel', path: tel.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _envoyerDemande(String adId) async {
    try {
      await ApiService.envoyerDemande(adId, widget.viewerUserId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Demande envoyée !'),
          backgroundColor: kGreen));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message), backgroundColor: kOrangeDark));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Connexion au serveur impossible'),
          backgroundColor: kRed));
    }
  }

  Future<void> _signaler() async {
    final motif = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Signaler cet utilisateur'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Motif (ex. propos inappropriés, faux profil…)',
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler')),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Envoyer'),
            ),
          ],
        );
      },
    );
    if (motif == null || motif.isEmpty) return;
    try {
      await ApiService.signaler(
        signaleUserId: widget.targetUserId,
        auteurId: widget.viewerUserId,
        motif: motif,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Signalement envoyé.'),
          backgroundColor: kGreen));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Signalement impossible pour le moment'),
          backgroundColor: kRed));
    }
  }

  String _membreDepuis() {
    final brut = _user!['creeLe'] as String?;
    if (brut == null || brut.isEmpty) return '';
    final d = DateTime.tryParse(brut);
    if (d == null) return '';
    const mois = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    return '${mois[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(title: const Text('Profil')),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: kOrange))
          : _user == null
              ? const Center(child: Text('Profil indisponible'))
              : _contenu(),
    );
  }

  Widget _contenu() {
    final prenom = _user!['prenom'] as String? ?? '';
    final nom = _user!['nom'] as String? ?? '';
    final telephone = (_user!['telephone'] as String? ?? '').replaceAll(' ', '');
    final email = _user!['email'] as String? ?? '';
    final quartier = _user!['quartier'] as String? ?? '';
    final verifie = _user!['verifie'] == true;
    final depuis = _membreDepuis();
    final photo = ApiService.resolvePhoto(_user!['photoUrl'] as String?);
    final initiale = prenom.isNotEmpty ? prenom[0].toUpperCase() : '?';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Carte identité
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kOrange, kOrangeDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kOrange.withAlpha(60),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: ClipOval(
                  child: photo != null
                      ? Image.network(
                          photo,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initiale(initiale),
                        )
                      : _initiale(initiale),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '$prenom $nom',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (verifie) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (quartier.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              quartier,
                              style: const TextStyle(fontSize: 13, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    if (depuis.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Membre depuis $depuis',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        verifie ? 'COMPTE VÉRIFIÉ' : 'NON VÉRIFIÉ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: verifie ? kGreen : const Color(0xFFB35A00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Contact (verrouille jusqu'a acceptation)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CONTACT',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: kTextSecondary),
              ),
              const SizedBox(height: 12),
              if (_contactDebloque) ...[
                if (telephone.isNotEmpty)
                  _ligneContact(
                    icone: Icons.phone_outlined,
                    valeur: '+223 $telephone',
                    actions: [
                      _boutonAction(Icons.call_rounded, kGreen, () => _appeler(telephone)),
                    ],
                  ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ligneContact(icone: Icons.email_outlined, valeur: email),
                ],
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kCream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 18, color: kOrange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Numéro et email visibles après acceptation de la demande.',
                          style: TextStyle(fontSize: 12, color: kTextSecondary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stats
        Row(
          children: [
            _bloc(_stats['adPublies'].toString(), 'AD publiés'),
            const SizedBox(width: 10),
            _bloc(_stats['trajetsOrganises'].toString(), 'Trajets organisés'),
            const SizedBox(width: 10),
            _bloc(_stats['signalements'].toString(), 'Signalements'),
          ],
        ),
        const SizedBox(height: 16),

        // Trajets actuels
        if (_trajets.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.route_rounded, size: 16, color: kOrange),
                    SizedBox(width: 8),
                    Text(
                      'TRAJETS ACTUELS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: kTextSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._trajets.map((t) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kCream,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${t['depart']} → ${t['destination']}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextPrimary),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${t['dateDeplacement']} à ${t['heureDepart']}'
                                  '${t['role'] == 'conducteur' ? ' · ${t['moyenTransport'] ?? ''} · ${t['placesDisponibles']} place(s)' : ''}',
                                  style: TextStyle(fontSize: 11, color: kTextSecondary),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _envoyerDemande(t['id'] as String),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: kOrange,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'Demander',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Signaler
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _signaler,
            icon: const Icon(Icons.flag_outlined, size: 18, color: kRed),
            label: const Text('Signaler cet utilisateur', style: TextStyle(color: kRed)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFF0D9D5)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _initiale(String initiale) {
    return Container(
      color: kOrangeDark,
      child: Center(
        child: Text(
          initiale,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
    );
  }

  Widget _ligneContact({required IconData icone, required String valeur, List<Widget> actions = const []}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: kOrangeLight, borderRadius: BorderRadius.circular(10)),
          child: Icon(icone, size: 18, color: kOrange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            valeur,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary),
          ),
        ),
        ...actions,
      ],
    );
  }

  Widget _boutonAction(IconData icone, Color couleur, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
        child: Icon(icone, size: 18, color: Colors.white),
      ),
    );
  }

  Widget _bloc(String valeur, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          children: [
            Text(
              valeur,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kOrange),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
