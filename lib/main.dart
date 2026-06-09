import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/main_layout.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding/step1_name_photo_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';
import 'theme/app_theme.dart';

export 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ooxrubdawfkjmkvdiznb.supabase.co',
    anonKey: 'sb_publishable_VwbuEKTQZ73gDSGJsUynPA_NyNynDUN',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swoop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

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
          child: Text(
            'swoop',
            style: AppTextStyles.brand.copyWith(fontSize: 28),
          ),
        ),
      );
    }
    return _homeWidget;
  }
}
