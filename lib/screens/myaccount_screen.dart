import 'package:flutter/material.dart';
import '../main.dart';

class MyAccountScreen extends StatelessWidget {
  const MyAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    String formatLastSignIn() {
      final lastSignIn = user?.lastSignInAt;
      if (lastSignIn == null) return 'Never';

      try {
        final DateTime date = DateTime.parse(lastSignIn.toString()).toLocal();
        return date.toString().split('.')[0];
      } catch (e) {
        return lastSignIn.toString();
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Account'), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blueGrey[100],
                    child: const Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.blueGrey,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Instruction 6: Key details of logged in user
            const Text(
              'Name',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              user?.email ?? 'User Email',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),

            const SizedBox(height: 30),
            const Divider(),

            _buildAccountTile(
              icon: Icons.email_outlined,
              title: 'Email Address',
              subtitle: user?.email ?? 'Not available',
            ),
            _buildAccountTile(
              icon: Icons.fingerprint,
              title: 'User ID',
              subtitle: user?.id ?? 'Not available',
            ),
            _buildAccountTile(
              icon: Icons.calendar_month_outlined,
              title: 'Last Sign In',
              subtitle: formatLastSignIn(),
            ),

            const SizedBox(height: 20),
            const Divider(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await supabase.auth.signOut();
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}
