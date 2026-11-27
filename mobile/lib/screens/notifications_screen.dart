import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/notification_read_service.dart';
import 'chat_screen.dart' deferred as chatDeferred;

/// Notifications construites à partir des demandes réelles (reçues / envoyées).
/// Ouvrir cet écran marque les notifications comme lues : le badge de la
/// cloche disparaît au retour à l'accueil.
class NotificationsScreen extends StatefulWidget {
  final String userId;
  const NotificationsScreen({super.key, required this.userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _charger();
  }

  void _recharger() => setState(() => _future = _charger());

  Future<void> _ouvrirChat({
    required String demandeId,
    required String partenaireNom,
    required String trajetLabel,
  }) async {
    await chatDeferred.loadLibrary();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => chatDeferred.ChatScreen(
          demandeId: demandeId,
          userId: widget.userId,
          partenaireNom: partenaireNom,
          trajetLabel: trajetLabel,
        ),
      ),
    );
  }

  Future<void> _traiterDemande(
    Map<String, dynamic> n,
    bool accepter,
  ) async {
    final demandeId = n['demandeId'] as String;
    try {
      if (accepter) {
        await ApiService.accepterDemande(demandeId, widget.userId);
      } else {
        await ApiService.refuserDemande(demandeId, widget.userId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(accepter ? 'Demande acceptée' : 'Demande refusée'),
        backgroundColor: accepter ? kGreen : kRed,
      ));
      _recharger();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action impossible : $e'), backgroundColor: kRed),
      );
    }
  }

  void _demanderDecision(Map<String, dynamic> n) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Répondre à la demande'),
        content: Text(
          '${n['titre']}\n\n${n['texte']}\n\nAccepter pour pouvoir discuter avec le partenaire ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Refuser'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Accepter'),
          ),
        ],
      ),
    ).then((ok) {
      if (ok != null) _traiterDemande(n, ok);
    });
  }

  void _onTap(Map<String, dynamic> n) {
    final statut = n['statut'] as String? ?? '';
    final type = n['type'] as String? ?? '';
    if (type == 'recue' && statut == 'en_attente') {
      _demanderDecision(n);
    } else if (statut == 'acceptee') {
      _ouvrirChat(
        demandeId: n['demandeId'] as String,
        partenaireNom: n['partenaireNom'] as String? ?? 'Partenaire',
        trajetLabel: n['trajetLabel'] as String? ?? 'Trajet',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _recharger,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kOrange));
          }
          final notifs = snapshot.data ?? [];
          if (notifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: kGreyLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_none_rounded,
                        size: 32, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 16),
                  const Text('Aucune notification',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary)),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Tu seras prévenu ici dès qu\'une demande arrive ou qu\'une réponse est donnée.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: kTextSecondary, height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: notifs
                .map((n) => _ligne(n, onTap: () => _onTap(n)))
                .toList(),
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _charger() async {
    final notifs = <Map<String, dynamic>>[];
    try {
      final recues = await ApiService.getDemandesRecues(widget.userId);
      for (final d in recues) {
        final m = d as Map<String, dynamic>;
        final demandeur = m['demandeur'] as Map<String, dynamic>;
        final ad = m['ad'] as Map<String, dynamic>;
        notifs.add({
          'id': m['id'] as String? ?? '',
          'demandeId': m['id'] as String? ?? '',
          'type': 'recue',
          'statut': m['statut'] as String? ?? '',
          'partenaireNom':
              '${demandeur['prenom'] ?? ''} ${demandeur['nom'] ?? ''}'.trim(),
          'trajetLabel': '${ad['depart']} → ${ad['destination']}',
          'icone': Icons.group_add_rounded,
          'titre': 'Nouvelle demande',
          'texte':
              '${demandeur['prenom']} ${demandeur['nom']} souhaite rejoindre ton trajet ${ad['depart']} → ${ad['destination']}',
          'couleur': kOrange,
          'bg': kOrangeLight,
        });
      }
      final envoyees =
          await ApiService.getDemandesEnvoyees(widget.userId);
      for (final d in envoyees) {
        final m = d as Map<String, dynamic>;
        final ad = m['ad'] as Map<String, dynamic>;
        final proprio = ad['proprietaire'] as Map<String, dynamic>;
        final statut = m['statut'] as String;
        if (statut == 'acceptee') {
          notifs.add({
            'id': m['id'] as String? ?? '',
            'demandeId': m['id'] as String? ?? '',
            'type': 'envoyee',
            'statut': statut,
            'partenaireNom':
                '${proprio['prenom'] ?? ''} ${proprio['nom'] ?? ''}'.trim(),
            'trajetLabel': '${ad['depart']} → ${ad['destination']}',
            'icone': Icons.check_circle_outline_rounded,
            'titre': 'Demande acceptée',
            'texte':
                '${proprio['prenom']} a accepté ta demande pour ${ad['depart']} → ${ad['destination']}. Appuie pour discuter.',
            'couleur': kGreen,
            'bg': kGreenLight,
          });
        } else if (statut == 'refusee') {
          notifs.add({
            'id': m['id'] as String? ?? '',
            'demandeId': m['id'] as String? ?? '',
            'type': 'envoyee',
            'statut': statut,
            'icone': Icons.cancel_outlined,
            'titre': 'Demande refusée',
            'texte': 'Ta demande pour le trajet de ${proprio['prenom']} n\'a pas été retenue.',
            'couleur': kRed,
            'bg': kRedLight,
          });
        }
      }
    } catch (_) {}
    // Ouvrir l'écran = notifications consultées.
    await NotificationReadService.marquerCommeLues(
      notifs.map((n) => n['id'] as String),
    );
    return notifs;
  }

  Widget _ligne(Map<String, dynamic> n, {required VoidCallback onTap}) {
    final actionnable = n['type'] == 'recue' && n['statut'] == 'en_attente' ||
        n['statut'] == 'acceptee';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: InkWell(
        onTap: actionnable ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: n['bg'] as Color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(n['icone'] as IconData,
                    size: 20, color: n['couleur'] as Color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n['titre'] as String,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      n['texte'] as String,
                      style: const TextStyle(
                          fontSize: 12, color: kTextSecondary, height: 1.4),
                    ),
                    if (actionnable)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          n['statut'] == 'acceptee'
                              ? 'Appuie pour discuter →'
                              : 'Appuie pour accepter ou refuser →',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: kOrange),
                        ),
                      ),
                  ],
                ),
              ),
              if (actionnable)
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: kTextSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
