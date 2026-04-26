import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/main_layout.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding/step1_name_photo_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ooxrubdawfkjmkvdiznb.supabase.co',
    anonKey: 'sb_publishable_VwbuEKTQZ73gDSGJsUynPA_NyNynDUN',
  );

  runApp(const MyApp());
}

// ── Design Tokens ──────────────────────────────────────────
class AppColors {
  static const Color bg = Color(0xFFF7F5F2); // warm cream
  static const Color card = Colors.white;
  static const Color primary = Color(0xFF1A1A2E); // deep navy
  static const Color accent = Color(0xFFE8505B); // coral — CTAs & active only
  static const Color subtle = Color(0xFFAAAAAA); // muted grey
  static const Color divider = Color(0xFFECEAE6); // warm divider
  static const Color success = Color(0xFF4CAF50);
  static const Color inputFill = Color(0xFFF0EEEB);
  static const Color chipBg = Color(0xFFEEECE8); // neutral chip background

  // All vibes use the same neutral chip — no rainbow
  static Color vibeBg(String? vibe) => const Color(0xFFEEECE8);
  static Color vibeFg(String? vibe) => const Color(0xFF1A1A2E);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Antigravity',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.bg,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.card,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bg,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: AppColors.primary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputFill,
          hintStyle: TextStyle(color: AppColors.subtle.withValues(alpha: 0.7)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.only(bottom: 16),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.subtle,
          type: BottomNavigationBarType.fixed,
          elevation: 20,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  Widget _homeWidget = const SizedBox.shrink();

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    supabase.auth.onAuthStateChange.listen((event) {
      if (mounted) _checkAuthState();
    });
  }

  Future<void> _checkAuthState() async {
    setState(() => _isLoading = true);

    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        _homeWidget = const LoginScreen();
        _isLoading = false;
      });
      return;
    }

    try {
      final data = await supabase
          .from('profiles')
          .select('onboarding_complete')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null || data['onboarding_complete'] != true) {
        setState(() => _homeWidget = const Step1NamePhotoScreen());
      } else {
        setState(() => _homeWidget = const MainLayout());
      }
    } catch (e) {
      setState(() => _homeWidget = const Step1NamePhotoScreen());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'antigravity',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return _homeWidget;
  }
}
