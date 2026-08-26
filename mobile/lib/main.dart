import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_scaffold.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';

const Color kOrange = Color(0xFFFF7700);
const Color kOrangeDark = Color(0xFFE25F00);
const Color kGreen = Color(0xFF1B7A2B);
const Color kCream = Color(0xFFFFF8F0);

/// Firebase est optionnel tant que google-services.json n'est pas ajouté :
/// l'app démarre et l'OTP est simulé (mode dev).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    AuthService.firebaseDisponible = true;
  } catch (_) {
    AuthService.firebaseDisponible = false;
  }
  runApp(const SirakeleApp());
}

/// Choisit l'écran de départ :
/// 1. Session existante -> accueil directement (reste connecté).
/// 2. Sinon onboarding (1re fois) ou accueil de bienvenue.
class EcranDemarrage extends StatelessWidget {
  const EcranDemarrage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(bool onboardingVu, ({String userId, String prenom})? session)>(
      future: _chargerEtat(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: kOrange)),
          );
        }
        final (onboardingVu, session) =
            snapshot.data ?? (false, null);
        if (session != null && session.userId.isNotEmpty) {
          return MainScaffold(
              userId: session.userId, prenom: session.prenom);
        }
        if (onboardingVu) {
          return const WelcomeScreen();
        }
        return const OnboardingScreen();
      },
    );
  }

  Future<(bool, ({String userId, String prenom})?)> _chargerEtat() async {
    final prefs = await SharedPreferences.getInstance();
    final session = await Session.lire();
    return (prefs.getBool('onboarding_vu') ?? false, session);
  }
}

class SirakeleApp extends StatelessWidget {
  const SirakeleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIRA KÉLÉ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kOrange,
          primary: kOrange,
          secondary: kGreen,
        ),
        scaffoldBackgroundColor: kCream,
        fontFamily: 'Inter',
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kOrange,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEDEAE2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEDEAE2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kOrange, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
      home: const EcranDemarrage(),
    );
  }
}
