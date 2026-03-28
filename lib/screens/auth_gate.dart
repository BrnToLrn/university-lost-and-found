import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; //
import '../main.dart';
import 'auth_screen.dart';
import 'dashboard_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      // Listens for login/logout changes in real-time
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;

        if (session != null) {
          return const DashboardScreen();
        }

        // Otherwise, stay on the login screen
        return const AuthScreen();
      },
    );
  }
}
