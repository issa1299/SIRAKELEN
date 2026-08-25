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
      if (!mounted) return;
      setState(() {
        _user = user;
        _stats = stats;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  Future<void> _signaler() async {
    final motif = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
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
          content: Text(
              'Signalement envoyé. Notre équipe va examiner ce profil.'),
          backgroundColor: kGreen));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Signalement impossible pour le moment'),
          backgroundColor: Color(0xFFA3392F)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil'), backgroundColor: Colors.transparent),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: kOrange))
          : _user == null
              ? const Center(child: Text('Profil indisponible'))
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xFFFFF3E6),
                          child: Icon(Icons.person,
                              color: kOrangeDark, size: 36),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${_user!['prenom']} ${_user!['nom']}',
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800)),
                            if (_user!['verifie'] == true) ...[
                              const SizedBox(width: 5),
                              const Icon(Icons.verified,
                                  color: kGreen, size: 17),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text('${_user!['quartier']}',
                            style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade600)),
                        const SizedBox(height: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            color: _user!['verifie'] == true
                                ? const Color(0xFFE2F2E5)
                                : const Color(0xFFFFE8D4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _user!['verifie'] == true
                                ? 'NUMÉRO VÉRIFIÉ'
                                : 'NON VÉRIFIÉ',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: _user!['verifie'] == true
                                  ? const Color(0xFF125A1E)
                                  : const Color(0xFFB35A00),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _bloc(_stats['adPublies'].toString(), 'AD publiés'),
                        const SizedBox(width: 9),
                        _bloc(_stats['trajetsOrganises'].toString(),
                            'Trajets organisés'),
                        const SizedBox(width: 9),
                        _bloc(_stats['signalements'].toString(),
                            'Signalements'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Le téléphone n'est PAS affiché : coordonnées masquées
                    // tant que la demande n'est pas acceptée (Architecture §15).
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Retour'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _signaler,
                      icon: const Icon(Icons.flag_outlined,
                          size: 16, color: Color(0xFFA3392F)),
                      label: const Text('Signaler cet utilisateur',
                          style: TextStyle(color: Color(0xFFA3392F))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFF0D9D5)),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _bloc(String valeur, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEAE2)),
        ),
        child: Column(
          children: [
            Text(valeur,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kOrangeDark)),
            const SizedBox(height: 3),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
