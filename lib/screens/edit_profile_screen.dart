import 'package:flutter/material.dart';
import '../main.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController firstNameController;
  late TextEditingController middleNameController;
  late TextEditingController lastNameController;
  late TextEditingController contactController;
  late TextEditingController studentIdController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(
      text: widget.userData['first_name'] ?? '',
    );
    middleNameController = TextEditingController(
      text: widget.userData['middle_name'] ?? '',
    );
    lastNameController = TextEditingController(
      text: widget.userData['last_name'] ?? '',
    );
    contactController = TextEditingController(
      text: widget.userData['contact'] ?? '',
    );
    studentIdController = TextEditingController(
      text: widget.userData['student_id'] ?? '',
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    contactController.dispose();
    studentIdController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      debugPrint('Saving profile for user: ${user.id}');

      await supabase
          .from('users')
          .upsert({
            'id': user.id,
            'first_name': firstNameController.text.trim(),
            'middle_name': middleNameController.text.trim(),
            'last_name': lastNameController.text.trim(),
            'contact': contactController.text.trim(),
            'student_id': studentIdController.text.trim(),
            'role': 'viewer',
          })
          .eq('id', user.id);

      debugPrint('Profile saved successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final isGuest = user == null || user.email == null || user.email!.isEmpty;

    // Prevent guests from editing profile
    if (isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile'), centerTitle: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 24),
                const Text(
                  'Guest users cannot edit their profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please log in with your email or Google account to edit your profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildTextField(
                controller: firstNameController,
                label: 'First Name',
                icon: Icons.person_outline,
              ),
              _buildTextField(
                controller: middleNameController,
                label: 'Middle Name',
                icon: Icons.person_outline,
              ),
              _buildTextField(
                controller: lastNameController,
                label: 'Last Name',
                icon: Icons.person_outline,
              ),
              _buildTextField(
                controller: contactController,
                label: 'Contact',
                icon: Icons.phone_outlined,
              ),
              _buildTextField(
                controller: studentIdController,
                label: 'Student ID',
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF003366),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF003366), width: 2),
          ),
        ),
      ),
    );
  }
}
