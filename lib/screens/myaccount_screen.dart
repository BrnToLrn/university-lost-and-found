import 'package:flutter/material.dart';
import '../main.dart';
import 'edit_profile_screen.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    final user = supabase.auth.currentUser;
    _userDataFuture = _getUserData(user?.id ?? '');
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      debugPrint('Fetching user data for: $userId');
      final response = await supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();
      debugPrint('User data fetched: $response');
      return response;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return {};
    }
  }

  void _refreshUserData() {
    final user = supabase.auth.currentUser;
    setState(() {
      _userDataFuture = _getUserData(user?.id ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final isGuest = user == null || user.email == null || user.email!.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        centerTitle: false,
        actions: [
          // Only show Edit Profile button if user is not a guest
          if (!isGuest)
            TextButton.icon(
              onPressed: () async {
                final userData = await _getUserData(user.id);
                if (context.mounted) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditProfileScreen(userData: userData),
                    ),
                  );
                  if (result == true) {
                    _refreshUserData();
                  }
                }
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUserData,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data ?? {};
          final firstName = userData['first_name'] ?? '';
          final middleName = userData['middle_name'] ?? '';
          final lastName = userData['last_name'] ?? '';
          final email = user?.email ?? 'Guest User';
          final userId = user?.id ?? '';
          final contact = userData['contact'] ?? '';
          final studentId = userData['student_id'] ?? '';
          final isGuestUser =
              user == null || user.email == null || user.email!.isEmpty;

          final fullName = [
            firstName,
            middleName,
            lastName,
          ].where((p) => p.isNotEmpty).join(' ');
          final initials =
              (firstName.isNotEmpty ? firstName[0] : '') +
              (lastName.isNotEmpty ? lastName[0] : '');

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar and Name Section
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFFE8EAF6),
                        child: Text(
                          initials.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3F51B5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Show guest notice if user is a guest
                  if (isGuestUser)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange[700],
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Guest users cannot edit their profile.',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Log in with your email or Google account to edit your profile and claim items.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isGuestUser) const SizedBox(height: 24),

                  _buildDetailRow(
                    Icons.fingerprint_outlined,
                    'User ID',
                    userId,
                  ),
                  _buildDetailRow(
                    Icons.person_outline,
                    'First Name',
                    firstName,
                  ),
                  _buildDetailRow(
                    Icons.person_outline,
                    'Middle Name',
                    middleName.isNotEmpty ? middleName : '-',
                  ),
                  _buildDetailRow(Icons.person_outline, 'Last Name', lastName),
                  _buildDetailRow(Icons.email_outlined, 'Email', email),
                  _buildDetailRow(
                    Icons.phone_outlined,
                    'Contact',
                    contact.isNotEmpty ? contact : '-',
                  ),
                  if (studentId.isNotEmpty) ...[
                    _buildDetailRow(
                      Icons.school_outlined,
                      'Student ID',
                      studentId,
                    ),
                  ],
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await supabase.auth.signOut();
                        if (context.mounted) {
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
