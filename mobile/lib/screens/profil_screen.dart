import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'modifier_profil_screen.dart';
import 'contact_urgence_screen.dart';
import 'mes_ad_screen.dart';
import 'login_screen.dart';

class ProfilScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onDeconnexion;
  const ProfilScreen({
    super.key,
    required this.userId,
    required this.onDeconnexion,
  });

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _contact;
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
      final user = await ApiService.getUser(widget.userId);
      final contact = await ApiService.getContactUrgence(widget.userId);
      final stats = await ApiService.getStats(widget.userId);
      if (!mounted) return;
      setState(() {
        _user = user;
        _contact = contact;
        _stats = stats;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kOrange)),
      );
    }
    final user = _user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Profil indisponible')));
    }
    final aContact = _contact != null;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFFFFF3E6),
                  child:
                      Icon(Icons.person, color: kOrangeDark, size: 36),
                ),
                const SizedBox(height: 10),
                Text('${user['prenom']} ${user['nom']}',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text('+223 ${user['telephone']}',
                    style: TextStyle(
                        fontSize: 11.5, color: Colors.grey.shade600)),
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: user['verifie'] == true
                        ? const Color(0xFFE2F2E5)
                        : const Color(0xFFFFE8D4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        user['verifie'] == true
                            ? Icons.verified
                            : Icons.hourglass_top,
                        size: 12,
                        color: user['verifie'] == true
                            ? const Color(0xFF125A1E)
                            : const Color(0xFFB35A00),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        user['verifie'] == true
                            ? 'NUMÉRO VÉRIFIÉ'
                            : 'VÉRIFICATION EN ATTENTE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: user['verifie'] == true
                              ? const Color(0xFF125A1E)
                              : const Color(0xFFB35A00),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _stat(_stats['adPublies'].toString(), 'AD publiés'),
                const SizedBox(width: 9),
                _stat(_stats['trajetsOrganises'].toString(),
                    'Trajets organisés'),
              ],
            ),
            const SizedBox(height: 14),
            if (!aContact)
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFDFC0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_in_talk,
                        color: Color(0xFFB35A00), size: 17),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Aucun contact d’urgence — tes partenaires ne pourront prévenir personne pour toi.',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFB35A00),
                            height: 1.4),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ContactUrgenceScreen(
                                  userId: widget.userId)),
                        );
                        _charger();
                      },
                      child: const Text('Ajouter',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: kOrangeDark)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEDEAE2)),
              ),
              child: Column(
                children: [
                  _menu(Icons.description_outlined, 'Mes Avis de Déplacement',
                      () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              MesAdScreen(userId: widget.userId)),
                    );
                    _charger();
                  }),
                  _menu(Icons.edit_outlined, 'Modifier mon profil', () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ModifierProfilScreen(
                              userId: widget.userId)),
                    );
                    _charger();
                  }),
                  _menu(Icons.phone_in_talk, 'Contact d’urgence', () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ContactUrgenceScreen(
                              userId: widget.userId)),
                    );
                    _charger();
                  }),
                  _menu(Icons.logout, 'Déconnexion', () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                    widget.onDeconnexion();
                  }, danger: true, derniere: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String valeur, String label) {
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
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: kOrangeDark)),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _menu(IconData icone, String titre, VoidCallback onTap,
      {bool danger = false, bool derniere = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: derniere
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFEDEAE2))),
        ),
        child: Row(
          children: [
            Icon(icone,
                size: 18,
                color: danger ? const Color(0xFFA3392F) : kOrangeDark),
            const SizedBox(width: 11),
            Expanded(
              child: Text(titre,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: danger
                          ? const Color(0xFFA3392F)
                          : const Color(0xFF1D1D1B))),
            ),
            if (!danger)
              Icon(Icons.chevron_right,
                  size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
