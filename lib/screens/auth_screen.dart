import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  void _showOtpDialog(BuildContext context, String email) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verify Email PIN'),
        content: TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter 6-digit code'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              try {
                await Supabase.instance.client.auth.verifyOTP(
                  email: email,
                  token: otpController.text.trim(),
                  type: OtpType.signup,
                );

                if (!context.mounted) return;
                Navigator.of(context).pop();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invalid PIN: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
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
              const SizedBox(height: 60), // Top spacing
              const Icon(
                Icons.travel_explore,
                size: 80,
                color: Color(0xFF003366),
              ),
              const SizedBox(height: 10),
              Text(
                'ADDU Lost & Found',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003366),
                ),
              ),
              const SizedBox(height: 30),
              SupaEmailAuth(
                redirectTo: 'io.supabase.flutter://login-callback/',
                onSignInComplete: (response) {},
                onSignUpComplete: (response) {
                  if (!context.mounted) return;
                  _showOtpDialog(context, response.user?.email ?? '');
                },
              ),

              // FIXED: Reduced gap with an "OR" label
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
                onSuccess: (response) {},
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
                    await Supabase.instance.client.auth.signInAnonymously();
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
