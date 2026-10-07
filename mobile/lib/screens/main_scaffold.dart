import 'package:flutter/material.dart';
import '../main.dart';
import 'home_screen.dart';
import 'profil_screen.dart';
import 'publier_screen.dart';

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
      backgroundColor: kCream,
      body: corps,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: kBorder, width: 1)),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _onglet,
            onTap: (i) async {
              if (i == 1) {
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
            backgroundColor: Colors.white,
            selectedItemColor: kOrange,
            unselectedItemColor: kTextSecondary,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            elevation: 0,
            items: [
              const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Accueil'),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle_outline_rounded),
                  activeIcon: Icon(Icons.add_circle_rounded),
                  label: 'Publier'),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }
}

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
