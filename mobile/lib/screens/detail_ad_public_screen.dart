import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../widgets/mini_trajet_map.dart';
import '../widgets/responsive_wrapper.dart';

// Ecran lourd charge a la demande.
import 'profil_autre_screen.dart' deferred as profilAutreDeferred;

/// Detail d'un AD parcouru : mini-carte, infos, action de demande, signalement.
class DetailAdPublicScreen extends StatefulWidget {
  final Map<String, dynamic> ad;
  final String userId;
  const DetailAdPublicScreen({super.key, required this.ad, required this.userId});

  @override
  State<DetailAdPublicScreen> createState() => _DetailAdPublicScreenState();
}

class _DetailAdPublicScreenState extends State<DetailAdPublicScreen> {
  bool _envoiEnCours = false;
  bool _dejaDemande = false;

  Map<String, dynamic> get ad => widget.ad;

  String _libelle(String? role) => role == 'conducteur' ? 'Conducteur' : 'Passager';

  Future<void> _demander() async {
    if (widget.userId.isEmpty) return;
    setState(() => _envoiEnCours = true);
    try {
      await ApiService.envoyerDemande(ad['id'] as String, widget.userId);
      if (!mounted) return;
      setState(() => _dejaDemande = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande envoyée !'), backgroundColor: kGreen),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: kOrangeDark),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connexion au serveur impossible'), backgroundColor: kRed),
      );
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  Future<void> _signaler() async {
    final motif = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Signaler ce trajet'),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Motif du signalement'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Signaler'),
            ),
          ],
        );
      },
    );
    if (motif == null || motif.isEmpty) return;
    try {
      await ApiService.signalerAd(adId: ad['id'] as String, auteurId: widget.userId, motif: motif);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signalement envoyé. Merci.'), backgroundColor: kGreen),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: kRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final proprietaire = ad['proprietaire'] as Map<String, dynamic>?;
    final isConducteur = ad['role'] == 'conducteur';
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(title: const Text('Détail du trajet')),
      body: ResponsiveWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MiniTrajetMap(ad: ad),
            const SizedBox(height: 16),
            // Recap
            _recapRow(Icons.route_rounded, 'Trajet', '${ad['depart']} → ${ad['destination']}'),
            _recapRow(Icons.calendar_today_rounded, 'Date', '${ad['dateDeplacement']}'),
            _recapRow(Icons.access_time_rounded, 'Horaire', '${ad['heureDepart']}'),
            if (isConducteur)
              _recapRow(Icons.event_seat_rounded, 'Transport', '${ad['moyenTransport'] ?? 'N/A'} · ${ad['placesDisponibles'] ?? 0} place(s)'),
            _recapRow(Icons.person_rounded, 'Rôle', _libelle(ad['role'] as String?)),
            if (ad['distanceKm'] != null)
              _recapRow(Icons.straighten_rounded, 'Distance', '≈ ${(ad['distanceKm'] as num).toStringAsFixed(1)} km'),
            const SizedBox(height: 16),
            // Proprietaire
            if (proprietaire != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: kOrangeLight,
                      child: Text(
                        '${(proprietaire['prenom'] as String? ?? '?')[0]}'.toUpperCase(),
                        style: const TextStyle(color: kOrange, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${proprietaire['prenom'] ?? ''} ${proprietaire['nom'] ?? ''}'.trim(),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextPrimary),
                                ),
                              ),
                              if (proprietaire['verifie'] == true) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, color: kGreen, size: 14),
                              ],
                            ],
                          ),
                          Text('Voir le profil', style: TextStyle(fontSize: 11, color: kOrange)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        profilAutreDeferred.loadLibrary().then((_) {
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => profilAutreDeferred.ProfilAutreScreen(
                                targetUserId: proprietaire['id'] as String,
                                viewerUserId: widget.userId,
                              ),
                            ),
                          );
                        });
                      },
                      child: const Text('Profil →'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Demander
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: (_envoiEnCours || _dejaDemande) ? null : _demander,
                icon: _envoiEnCours
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(_dejaDemande ? Icons.check_rounded : Icons.send_rounded, size: 20),
                label: Text(_dejaDemande ? 'Demande envoyée' : 'Demander'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _signaler,
                icon: const Icon(Icons.flag_outlined, size: 18, color: kRed),
                label: const Text('Signaler ce trajet', style: TextStyle(color: kRed)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFF0D9D5))),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _recapRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: kOrangeLight, borderRadius: BorderRadius.circular(8)),
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
