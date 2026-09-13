import 'package:flutter/material.dart';
import 'data/services/auth_service.dart';
import 'ui/features/auth/login_view.dart';
import 'ui/features/home/home_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, _) {
        if (AuthService().isAuthenticated) {
          return const HomeView();
        }
        return const LoginView();
      },
    );
  }
}
