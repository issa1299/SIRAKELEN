import 'package:flutter/material.dart';
import '../main.dart';
import 'home_screen.dart';
import 'profil_screen.dart';
import 'notifications_screen.dart';
import 'publier_screen.dart';

/// Squelette principal : 3 onglets (Accueil / Publier / Profil).
/// L'onglet Publier ouvre l'écran de publication, puis revient ici.
class MainScaffold extends StatefulWidget {
  final String userId;
  final String prenom;
  const MainScaffold(
      {super.key, required this.userId, this.prenom = ''});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _onglet = 0;
  int _notificationsNonLues = 0;
  Key _homeKey = UniqueKey();

  void _recharger() {
    setState(() => _homeKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    Widget corps;
    switch (_onglet) {
      case 2:
        corps = ProfilScreen(userId: widget.userId, onDeconnexion: () {});
        break;
      default:
        corps = HomeScreen(
          key: _homeKey,
          prenom: widget.prenom,
          userId: widget.userId,
        );
    }

    return Scaffold(
      body: corps,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _onglet,
        onTap: (i) async {
          if (i == 1) {
            // Onglet Publier : ouvre l'écran de publication par-dessus.
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    _PagePublier(userId: widget.userId, onRetour: _recharger),
              ),
            );
            _recharger();
            return;
          }
          setState(() => _onglet = i);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kOrange,
        unselectedItemColor: Colors.grey.shade400,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Accueil'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), label: 'Publier'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil'),
        ],
      ),
      floatingActionButton: _onglet == 0 && widget.userId.isNotEmpty
          ? FloatingActionButton(
              heroTag: 'notifs',
              onPressed: () async {
                final avant = _notificationsNonLues;
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          NotificationsScreen(userId: widget.userId)),
                );
                if (mounted && avant > 0) {
                  setState(() => _notificationsNonLues = 0);
                }
              },
              backgroundColor: kOrange,
              child: const Icon(Icons.notifications_none,
                  color: Colors.white),
            )
          : null,
    );
  }
}

/// Écran de publication plein écran (onglet central).
class _PagePublier extends StatelessWidget {
  final String userId;
  final VoidCallback onRetour;
  const _PagePublier({required this.userId, required this.onRetour});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PublierScreen(userId: userId),
    );
  }
}
