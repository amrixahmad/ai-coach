import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/services/supabase_service.dart';
import 'ui/features/auth/login_view.dart';
import 'ui/features/home/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase initialization with fallback keys (Replace with actual env keys)
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://your-supabase-project.supabase.co');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'your-anon-key');

  if (supabaseUrl.contains('supabase.co')) {
    await SupabaseService.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  runApp(const PickleballCoachApp());
}

class PickleballCoachApp extends StatelessWidget {
  const PickleballCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Pickleball Coach',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService().authStateChanges,
      builder: (context, snapshot) {
        final session = SupabaseService().client.auth.currentSession;
        if (session != null) {
          return const HomeView();
        }
        return const LoginView();
      },
    );
  }
}
