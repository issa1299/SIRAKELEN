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
    final telephone = (user['telephone'] as String? ?? '').replaceAll(' ', '');
    final email = user['email'] as String? ?? '';
    final quartier = user['quartier'] as String? ?? '';
    final verifie = user['verifie'] == true;
    final depuis = _membreDepuis();
    final photo = ApiService.resolvePhoto(user['photoUrl'] as String?);
    final initials = '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase();

    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _charger,
          color: kOrange,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // Bannière + avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 130,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kOrange, kOrangeDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 40,
                          bottom: -40,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 20,
                          top: 18,
                          child: Text(
                            'Mon profil',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: -34,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: photo != null
                            ? Image.network(
                                photo,
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _initiale(initials),
                              )
                            : _initiale(initials),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: -24,
                    child: GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ModifierProfilScreen(userId: widget.userId)),
                        );
                        _charger();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined, size: 15, color: kOrange),
                            SizedBox(width: 6),
                            Text('Modifier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kOrange)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom + badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '$prenom $nom',
                            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: kTextPrimary),
                          ),
                        ),
                        if (verifie) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, color: kGreen, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: verifie ? kGreenLight : const Color(0xFFFFE8D4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            verifie ? 'COMPTE VÉRIFIÉ' : 'EN ATTENTE DE VÉRIFICATION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: verifie ? kGreen : const Color(0xFFB35A00),
                            ),
                          ),
                        ),
                        if (depuis.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Text(
                            'Membre depuis $depuis',
                            style: TextStyle(fontSize: 12, color: kTextSecondary),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Carte infos
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder),
                      ),
                      child: Column(
                        children: [
                          if (telephone.isNotEmpty) _info(Icons.phone_outlined, '+223 $telephone'),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _info(Icons.email_outlined, email),
                          ],
                          if (quartier.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _info(Icons.location_on_outlined, quartier),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats
                    Row(
                      children: [
                        _stat(_stats['adPublies'].toString(), 'AD publiés'),
                        const SizedBox(width: 10),
                        _stat(_stats['trajetsOrganises'].toString(), 'Trajets organisés'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Alerte contact urgence
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
                            const Expanded(
                              child: Text(
                                'Aucun contact d\'urgence. Ajoute un contact pour ta sécurité.',
                                style: TextStyle(fontSize: 12, color: kOrange, height: 1.4),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ContactUrgenceScreen(userId: widget.userId)),
                                );
                                _charger();
                              },
                              child: const Text(
                                'Ajouter',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kOrange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!aContact) const SizedBox(height: 12),

                    // Menu
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initiale(String initials) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [kOrange, kOrangeDark]),
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
    );
  }

  Widget _info(IconData icone, String valeur) {
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
      ],
    );
  }

  Widget _stat(String valeur, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          children: [
            Text(
              valeur,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kOrange),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextSecondary),
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
        bottom: isLast ? const Radius.circular(15) : Radius.zero,
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: danger ? kRedLight : kOrangeLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, size: 18, color: danger ? kRed : kOrange),
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
