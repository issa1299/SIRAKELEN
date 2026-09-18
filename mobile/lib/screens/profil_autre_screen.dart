import 'package:flutter/material.dart';
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
      if (!mounted) return;
      setState(() {
        _user = user;
        _stats = stats;
        _trajets = trajets;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
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
            decoration: InputDecoration(
              hintText: 'Motif (ex. propos inappropriés, faux profil…)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler')),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: FilledButton.styleFrom(backgroundColor: kOrange),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(title: const Text('Profil')),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: kOrange))
          : _user == null
              ? const Center(child: Text('Profil indisponible'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Profile header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [kOrange, kOrangeDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: kOrange.withAlpha(50),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: (_user!['photoUrl'] != null && (_user!['photoUrl'] as String).isNotEmpty)
                                  ? Image.network(
                                      '${ApiService.baseUrl}${_user!['photoUrl']}',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          '${(_user!['prenom'] as String).isNotEmpty ? (_user!['prenom'] as String)[0] : ''}',
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        '${(_user!['prenom'] as String).isNotEmpty ? (_user!['prenom'] as String)[0] : ''}',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${_user!['prenom']} ${_user!['nom']}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: kTextPrimary,
                                ),
                              ),
                              if (_user!['verifie'] == true) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified_rounded, color: kGreen, size: 20),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_user!['quartier']}',
                            style: TextStyle(fontSize: 13, color: kTextSecondary),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _user!['verifie'] == true ? kGreenLight : const Color(0xFFFFE8D4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _user!['verifie'] == true ? 'VÉRIFIÉ' : 'NON VÉRIFIÉ',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _user!['verifie'] == true ? kGreen : const Color(0xFFB35A00),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

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
                    const SizedBox(height: 20),

                    // Current trips
                    if (_trajets.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: kOrangeLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.route_rounded, size: 14, color: kOrange),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Trajets actuels',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: kTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._trajets.map((t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${t['depart']} → ${t['destination']}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: kTextPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${t['heureDepart']}'
                                              '${t['role'] == 'conducteur' ? ' · ${t['placesDisponibles']} place(s)' : ''}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: kTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _envoyerDemande(t['id'] as String),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: kOrange,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: const Text(
                                            'Demander',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
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

                    // Buttons
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Retour'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: _signaler,
                        icon: const Icon(Icons.flag_outlined, size: 18, color: kRed),
                        label: const Text(
                          'Signaler cet utilisateur',
                          style: TextStyle(color: kRed),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFF0D9D5)),
                        ),
                      ),
                    ),
                  ],
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: kOrange,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
