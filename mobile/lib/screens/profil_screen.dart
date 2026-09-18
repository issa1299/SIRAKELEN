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
        backgroundColor: kCream,
        body: Center(child: CircularProgressIndicator(color: kOrange)),
      );
    }
    final user = _user;
    if (user == null) {
      return const Scaffold(
        backgroundColor: kCream,
        body: Center(child: Text('Profil indisponible')),
      );
    }
    final aContact = _contact != null;
    final prenom = user['prenom'] as String? ?? '';
    final nom = user['nom'] as String? ?? '';
    final initials = '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase();

    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar and name
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
                      child: (user['photoUrl'] != null && (user['photoUrl'] as String).isNotEmpty)
                          ? Image.network(
                              '${ApiService.baseUrl}${user['photoUrl']}',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  initials,
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
                                initials,
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
                  Text(
                    '$prenom $nom',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+223 ${user['telephone']}',
                    style: TextStyle(fontSize: 13, color: kTextSecondary),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: user['verifie'] == true ? kGreenLight : const Color(0xFFFFE8D4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user['verifie'] == true
                              ? Icons.verified_rounded
                              : Icons.hourglass_top_rounded,
                          size: 14,
                          color: user['verifie'] == true ? kGreen : const Color(0xFFB35A00),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user['verifie'] == true ? 'VÉRIFIÉ' : 'EN ATTENTE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: user['verifie'] == true ? kGreen : const Color(0xFFB35A00),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats
            Row(
              children: [
                _stat(_stats['adPublies'].toString(), 'AD publiés'),
                const SizedBox(width: 10),
                _stat(_stats['trajetsOrganises'].toString(), 'Trajets organisés'),
              ],
            ),
            const SizedBox(height: 16),

            // Emergency contact alert
            if (!aContact)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kOrange.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_in_talk_rounded, color: kOrange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aucun contact d\'urgence. Ajoute un contact pour ta sécurité.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: kOrange,
                          height: 1.4,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ContactUrgenceScreen(userId: widget.userId)),
                        );
                        _charger();
                      },
                      child: const Text(
                        'Ajouter',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // Menu card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                children: [
                  _menu(Icons.description_outlined, 'Mes Avis de Déplacement', () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MesAdScreen(userId: widget.userId)),
                    );
                    _charger();
                  }),
                  _menu(Icons.edit_outlined, 'Modifier mon profil', () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ModifierProfilScreen(userId: widget.userId)),
                    );
                    _charger();
                  }),
                  _menu(Icons.phone_in_talk_rounded, 'Contact d\'urgence', () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ContactUrgenceScreen(userId: widget.userId)),
                    );
                    _charger();
                  }),
                  _menu(Icons.logout_rounded, 'Déconnexion', () async {
                    await Session.effacer();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                    widget.onDeconnexion();
                  }, danger: true, isLast: true),
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
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: kOrange,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menu(IconData icone, String titre, VoidCallback onTap,
      {bool danger = false, bool isLast = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        bottom: isLast ? const Radius.circular(13) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: isLast
            ? null
            : const BoxDecoration(
                border: Border(bottom: BorderSide(color: kBorder)),
              ),
        child: Row(
          children: [
            Icon(
              icone,
              size: 20,
              color: danger ? kRed : kOrange,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                titre,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: danger ? kRed : kTextPrimary,
                ),
              ),
            ),
            if (!danger)
              Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
