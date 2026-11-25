import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/responsive_wrapper.dart';
import 'home_screen.dart';

// Ecrans lourds charges a la demande (deferred loading).
import 'profil_screen.dart' deferred as profilDeferred;
import 'publier_screen.dart' deferred as publierDeferred;

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
        corps = FutureBuilder<void>(
          future: profilDeferred.loadLibrary(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: kOrange),
              );
            }
            return profilDeferred.ProfilScreen(
              userId: widget.userId,
              onDeconnexion: () {},
            );
          },
        );
        break;
      default:
        corps = HomeScreen(
          key: _homeKey,
          prenom: widget.prenom,
          userId: widget.userId,
        );
    }

    return PopScope(
      canPop: _onglet == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _onglet != 0) {
          setState(() => _onglet = 0);
        }
      },
      child: Scaffold(
        backgroundColor: kCream,
        body: ResponsiveWrapper(child: corps),
        bottomNavigationBar: ResponsiveWrapper(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: kBorder, width: 1)),
          ),
          child: SafeArea(
            child: BottomNavigationBar(
              currentIndex: _onglet,
              onTap: (i) async {
                if (i == 1) {
                  await publierDeferred.loadLibrary();
                  if (!mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GestureDetector(
                        onTap: () => FocusScope.of(context).unfocus(),
                        child: publierDeferred.PublierScreen(userId: widget.userId),
                      ),
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
      ),
      ),
    );
  }
}

// _PagePublier supprime — remplacé par l'import différé direct dans main_scaffold.
