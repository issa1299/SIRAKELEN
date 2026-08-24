import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_service.dart';

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
      home: const WelcomeScreen(),
    );
  }
}
