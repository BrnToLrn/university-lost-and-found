import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart'; //
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kptcqhdiszsjzqyxszjg.supabase.co', //
    anonKey: 'sb_publishable_l8T-n4Ro0ChubQx5ExIIqw_mSeTqCGi', //
  );

  runApp(const MyApp());
}

// Global access to Supabase client
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'University Lost & Found',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.montserratTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003366), // University Blue
          primary: const Color(0xFF003366),
          secondary: const Color(0xFFFFCC00), // University Gold
        ),
      ),
      home: const AuthGate(),
    );
  }
}
