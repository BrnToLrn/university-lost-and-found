import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _setUserRole(String userId, String role) async {
    try {
      await Supabase.instance.client.from('users').upsert({
        'id': userId,
        'role': role,
        'first_name': '',
        'middle_name': '',
        'last_name': '',
        'contact': '',
        'student_id': '',
      }).select();
      debugPrint('User record created/updated successfully');
    } catch (e) {
      debugPrint('Error setting user role: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating user profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const Icon(
                Icons.travel_explore,
                size: 80,
                color: Color(0xFF003366),
              ),
              const SizedBox(height: 10),
              Text(
                'University Lost & Found',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003366),
                ),
              ),
              const SizedBox(height: 30),
              SupaEmailAuth(
                redirectTo: 'io.supabase.flutter://login-callback',
                onSignInComplete: (response) {
                  _setUserRole(response.user!.id, 'viewer');
                },
                onSignUpComplete: (response) {
                  _setUserRole(response.user!.id, 'viewer');
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "OR",
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),

              SupaSocialsAuth(
                socialProviders: [OAuthProvider.google],
                redirectUrl: 'io.supabase.flutter://login-callback',
                onSuccess: (response) {
                  _setUserRole(response.user.id, 'viewer');
                },
                onError: (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.person_outline),
                label: const Text('Continue as Guest'),
                onPressed: () async {
                  try {
                    final response = await Supabase.instance.client.auth
                        .signInAnonymously();
                    _setUserRole(response.user!.id, 'viewer');
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Guest Login Failed: $e')),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Color(0xFF003366)),
                  foregroundColor: const Color(0xFF003366),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
