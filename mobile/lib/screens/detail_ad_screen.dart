import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/whatsapp_helper.dart';
import 'profil_autre_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailAdScreen extends StatefulWidget {
  final String adId;
  final String userId;
  const DetailAdScreen({super.key, required this.adId, required this.userId});

  @override
  State<DetailAdScreen> createState() => _DetailAdScreenState();
}

class _DetailAdScreenState extends State<DetailAdScreen> {
  Map<String, dynamic>? _ad;
  Map<String, dynamic>? _partenaire;
  Map<String, dynamic>? _contactUrgence;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final ads = await ApiService.mesAds(widget.userId);
      final ad = ads.where((a) => a['id'] == widget.adId).firstOrNull;
      if (ad != null && mounted) {
        setState(() {
          _ad = ad as Map<String, dynamic>;
          _chargement = false;
        });
        // Load partner info if finalizing
        if (_ad!['statut'] == 'en_cours_de_finalisation') {
          _chargerPartenaire();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _chargerPartenaire() async {
    try {
      final demandes = await ApiService.getDemandesRecues(widget.userId);
      final acceptee = demandes.where((d) => d['statut'] == 'acceptee').toList();
      if (acceptee.isNotEmpty && mounted) {
        final demandeur = acceptee.first['demandeur'] as Map<String, dynamic>;
        setState(() => _partenaire = demandeur);
        // Load partner's emergency contact
        _chargerContactUrgence(demandeur['id'] as String);
      }
    } catch (_) {}
  }

  Future<void> _chargerContactUrgence(String userId) async {
    try {
      final user = await ApiService.getUser(userId);
      if (user['contactUrgence'] != null && mounted) {
        setState(() => _contactUrgence = user['contactUrgence'] as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  Future<void> _marquerOrganise() async {
    try {
      await ApiService.marquerOrganise(widget.adId, widget.userId);
      await _charger();
    } catch (_) {}
  }

  Future<void> _annulerAd() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Annuler cet AD ?'),
        content: const Text('Ton trajet ne sera plus visible par les autres utilisateurs.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, annuler', style: TextStyle(color: kRed)),
          ),
        ],
      ),
    );
    if (confirme == true) {
      try {
        await ApiService.annulerAd(widget.adId, widget.userId);
        if (mounted) Navigator.pop(context);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return Scaffold(
        backgroundColor: kCream,
        appBar: AppBar(title: const Text('Détail de mon AD')),
        body: const Center(child: CircularProgressIndicator(color: kOrange)),
      );
    }
    if (_ad == null) {
      return Scaffold(
        backgroundColor: kCream,
        appBar: AppBar(title: const Text('Détail de mon AD')),
        body: const Center(child: Text('AD introuvable')),
      );
    }

    final statut = _ad!['statut'] as String;
    final isFinalizing = statut == 'en_cours_de_finalisation';

    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(title: const Text('Détail de mon AD')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isFinalizing ? const Color(0xFFFFE8D4) : kGreenLight,
                borderRadius: BorderRadius.circular(20),
                border: isFinalizing
                    ? Border.all(color: const Color(0xFFFF9A3D))
                    : Border.all(color: kGreen.withAlpha(80)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFinalizing ? Icons.access_time_rounded : Icons.check_circle_rounded,
                    size: 14,
                    color: isFinalizing ? const Color(0xFFB35A00) : kGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isFinalizing ? 'EN COURS DE FINALISATION' : 'ACTIF',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isFinalizing ? const Color(0xFFB35A00) : kGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Map placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5F3EE), Color(0xFFEDE9E0)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, color: kTextSecondary.withAlpha(100), size: 36),
                    const SizedBox(height: 6),
                    Text(
                      'Carte à venir',
                      style: TextStyle(fontSize: 12, color: kTextSecondary.withAlpha(150)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Recap rows
            _recapRow(Icons.route_rounded, 'Trajet', '${_ad!['depart']} → ${_ad!['destination']}'),
            _recapRow(Icons.calendar_today_rounded, 'Date', '${_ad!['dateDeplacement']}'),
            _recapRow(Icons.access_time_rounded, 'Horaire', '${_ad!['heureDepart']}'),
            if (_ad!['role'] == 'conducteur')
              _recapRow(Icons.event_seat_rounded, 'Transport',
                  '${_ad!['moyenTransport'] ?? 'N/A'} · ${_ad!['placesDisponibles'] ?? 0} place(s)'),
            _recapRow(Icons.person_rounded, 'Rôle', _ad!['role'] == 'conducteur' ? 'Conducteur' : 'Passager'),
            const SizedBox(height: 16),

            // Partner section (when finalizing)
            if (isFinalizing && _partenaire != null) ...[
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilAutreScreen(
                      targetUserId: _partenaire!['id'] as String,
                      viewerUserId: widget.userId,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded, color: kOrange, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${_partenaire!['prenom']} ${_partenaire!['nom']}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kOrange,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              _recapRow(Icons.phone_rounded, 'Téléphone', '${_partenaire!['telephone']}'),
              const SizedBox(height: 12),
              // WhatsApp button
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await WhatsAppHelper.ouvrir(
                      telephone: '${_partenaire!['telephone']}',
                      message: 'Bonjour ${_partenaire!['prenom']}, je te contacte au sujet du trajet SIRA KELEN.',
                    );
                  },
                  icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'Contacter via WhatsApp',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
              // Emergency contact
              if (_contactUrgence != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF9A3D), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB35A00), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'EN CAS D\'IMPRÉVU SUR LA ROUTINE',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: const Color(0xFFB35A00),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Contact d\'urgence de ${_partenaire!['prenom']}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_contactUrgence!['nom']} — ${_contactUrgence!['lien'] ?? 'Contact'}',
                        style: const TextStyle(fontSize: 13, color: kTextSecondary),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final tel = Uri.parse('tel:${_contactUrgence!['telephone']}');
                            if (await canLaunchUrl(tel)) await launchUrl(tel);
                          },
                          icon: const Icon(Icons.phone_rounded, size: 16, color: Color(0xFFB35A00)),
                          label: Text(
                            'Appeler le ${_contactUrgence!['telephone']}',
                            style: const TextStyle(color: Color(0xFFB35A00), fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB35A00),
                            side: const BorderSide(color: Color(0xFFB35A00)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            const SizedBox(height: 20),

            // Actions
            if (isFinalizing)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _marquerOrganise,
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: const Text('Marquer comme trajet organisé'),
                  style: FilledButton.styleFrom(backgroundColor: kGreen),
                ),
              ),
            if (isFinalizing) const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _annulerAd,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kRed,
                  side: const BorderSide(color: kRed),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Annuler cet AD', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recapRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: kOrangeLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: kOrange),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 13, color: kTextSecondary)),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
