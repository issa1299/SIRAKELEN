import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/notification_read_service.dart';
import 'chat_screen.dart' deferred as chatDeferred;

/// Liste des échanges possibles : demandes reçues / envoyées en attente ou
/// acceptées. Restaure l'accès à la messagerie sur Android et Web.
class ConversationsScreen extends StatefulWidget {
  final String userId;
  const ConversationsScreen({super.key, required this.userId});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _charger();
  }

  void _recharger() => setState(() => _future = _charger());

  Future<List<Map<String, dynamic>>> _charger() async {
    try {
      final [recues, envoyees] = await Future.wait([
        ApiService.getDemandesRecues(widget.userId),
        ApiService.getDemandesEnvoyees(widget.userId),
      ]);
      final result = <Map<String, dynamic>>[];
      for (final d in recues) {
        final m = d as Map<String, dynamic>;
        final statut = m['statut'] as String? ?? '';
        if (statut != 'en_attente' && statut != 'acceptee') continue;
        final demandeur = m['demandeur'] as Map<String, dynamic>;
        final ad = m['ad'] as Map<String, dynamic>;
        result.add({
          'id': m['id'] as String? ?? '',
          'type': 'recue',
          'statut': statut,
          'autreNom':
              '${demandeur['prenom'] ?? ''} ${demandeur['nom'] ?? ''}'.trim(),
          'trajetLabel': '${ad['depart']} → ${ad['destination']}',
        });
      }
      for (final d in envoyees) {
        final m = d as Map<String, dynamic>;
        final statut = m['statut'] as String? ?? '';
        if (statut != 'en_attente' && statut != 'acceptee') continue;
        final ad = m['ad'] as Map<String, dynamic>;
        final proprio = ad['proprietaire'] as Map<String, dynamic>;
        result.add({
          'id': m['id'] as String? ?? '',
          'type': 'envoyee',
          'statut': statut,
          'autreNom':
              '${proprio['prenom'] ?? ''} ${proprio['nom'] ?? ''}'.trim(),
          'trajetLabel': '${ad['depart']} → ${ad['destination']}',
        });
      }
      result.sort((a, b) => (b['id'] as String).compareTo(a['id'] as String));
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<void> _ouvrirChat(Map<String, dynamic> c) async {
    await chatDeferred.loadLibrary();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => chatDeferred.ChatScreen(
          demandeId: c['id'] as String,
          userId: widget.userId,
          partenaireNom: c['autreNom'] as String,
          trajetLabel: c['trajetLabel'] as String,
        ),
      ),
    ).then((_) => _recharger());
  }

  Future<void> _accepterRefuser(Map<String, dynamic> c, bool accepter) async {
    try {
      if (accepter) {
        await ApiService.accepterDemande(c['id'] as String, widget.userId);
      } else {
        await ApiService.refuserDemande(c['id'] as String, widget.userId);
      }
      // La demande traitée n'est plus « à traiter ».
      await NotificationReadService.marquerCommeLues([c['id'] as String]);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        title: const Text('Conversations'),
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
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                        color: kGreyLight, shape: BoxShape.circle),
                    child: Icon(Icons.chat_bubble_outline_rounded,
                        size: 32, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 16),
                  const Text('Aucune conversation',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary)),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Les demandes acceptées ou en attente apparaissent ici.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: kTextSecondary),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _recharger(),
            color: kOrange,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              itemBuilder: (context, i) => _ligne(items[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _ligne(Map<String, dynamic> c) {
    final estRecue = c['type'] == 'recue';
    final acceptee = c['statut'] == 'acceptee';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: kOrangeLight,
                child: Icon(Icons.person_rounded, color: kOrange, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['autreNom'] as String,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary)),
                    const SizedBox(height: 3),
                    Text(c['trajetLabel'] as String,
                        style: const TextStyle(
                            fontSize: 11, color: kTextSecondary)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: acceptee ? kGreenLight : kOrangeLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  acceptee ? 'Acceptée' : 'En attente',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: acceptee ? kGreen : kOrange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (acceptee)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _ouvrirChat(c),
                icon: const Icon(Icons.chat_rounded, size: 16),
                label: const Text('Discuter'),
                style: FilledButton.styleFrom(backgroundColor: kOrange),
              ),
            )
          else if (estRecue)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _accepterRefuser(c, false),
                  child: const Text('Refuser',
                      style: TextStyle(color: kRed)),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: () => _accepterRefuser(c, true),
                  style: FilledButton.styleFrom(backgroundColor: kGreen),
                  child: const Text('Accepter'),
                ),
              ],
            )
          else
            const Align(
              alignment: Alignment.centerRight,
              child: Text('En attente de réponse…',
                  style: TextStyle(fontSize: 11, color: kTextSecondary)),
            ),
        ],
      ),
    );
  }
}
