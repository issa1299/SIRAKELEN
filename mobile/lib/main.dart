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
const Color kOrangeLight = Color(0xFFFFF3E6);
const Color kGreen = Color(0xFF1B7A2B);
const Color kGreenLight = Color(0xFFE2F2E5);
const Color kCream = Color(0xFFFDF6EE);
const Color kRed = Color(0xFFD32F2F);
const Color kRedLight = Color(0xFFFDECEA);
const Color kGrey = Color(0xFF757575);
const Color kGreyLight = Color(0xFFF5F5F0);
const Color kBorder = Color(0xFFE8E4DD);
const Color kCardShadow = Color(0x1A000000);
const Color kTextPrimary = Color(0xFF1A1A1A);
const Color kTextSecondary = Color(0xFF6B6B6B);

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
            backgroundColor: kCream,
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

    if (session != null && session.userId.isNotEmpty) {
      try {
        final user = await ApiService.getUser(session.userId);
        if (user == null) {
          await Session.effacer();
          return (prefs.getBool('onboarding_vu') ?? false, null);
        }
      } catch (_) {
        await Session.effacer();
        return (prefs.getBool('onboarding_vu') ?? false, null);
      }
    }

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
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kOrange,
          primary: kOrange,
          secondary: kGreen,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSurface: kTextPrimary,
        ),
        scaffoldBackgroundColor: kCream,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: kTextPrimary),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: kBorder, width: 1),
          ),
          margin: const EdgeInsets.only(bottom: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kOrange,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kOrange,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kTextPrimary,
            minimumSize: const Size.fromHeight(54),
            side: const BorderSide(color: kBorder, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: kOrange,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kOrange, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kRed),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kRed, width: 2),
          ),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          labelStyle: const TextStyle(color: kTextSecondary, fontSize: 14),
          prefixIconColor: kTextSecondary,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: kGreyLight,
          selectedColor: kOrange,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dividerTheme: const DividerThemeData(
          color: kBorder,
          thickness: 1,
          space: 0,
        ),
      ),
      home: const EcranDemarrage(),
    );
  }
}
