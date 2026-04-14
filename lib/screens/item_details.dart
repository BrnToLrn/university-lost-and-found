import 'package:flutter/material.dart';
import '../main.dart';

class ItemDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getCategoryName(),
      builder: (context, categorySnapshot) {
        return FutureBuilder<String>(
          future: _getSubmittedByName(item['user_id']),
          builder: (context, submittedBySnapshot) {
            return _buildDetails(
              context,
              categorySnapshot.data ?? 'Uncategorized',
              submittedBySnapshot.data ?? 'Unknown',
            );
          },
        );
      },
    );
  }

  Future<String> _getCategoryName() async {
    try {
      final categoryId = item['category_id'];
      if (categoryId == null) return 'Uncategorized';

      final response = await supabase
          .from('categories')
          .select('name')
          .eq('id', categoryId)
          .single();

      return response['name'] ?? 'Uncategorized';
    } catch (e) {
      return 'Uncategorized';
    }
  }

  Future<String> _getSubmittedByName(String? userId) async {
    if (userId == null) return 'Unknown';
    try {
      final response = await supabase
          .from('users')
          .select('first_name, middle_name, last_name')
          .eq('id', userId)
          .single();

      final firstName = response['first_name'] ?? '';
      final middleName = response['middle_name'] ?? '';
      final lastName = response['last_name'] ?? '';

      final nameParts = [
        firstName,
        middleName,
        lastName,
      ].where((part) => part.isNotEmpty).toList();
      final fullName = nameParts.join(' ');

      return fullName.isNotEmpty ? fullName : 'Unknown';
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return 'Unknown';
    }
  }

  Widget _buildDetails(
    BuildContext context,
    String category,
    String submittedBy,
  ) {
    debugPrint('Item data: $item');
    final String itemName = (item['title'] ?? 'Unnamed Item').toString();
    final String description =
        (item['description'] ?? 'No description provided.').toString();
    final String location = (item['location'] ?? 'Not specified').toString();
    final String itemType = (item['type'] ?? 'unknown')
        .toString()
        .toLowerCase();
    final String status = (item['status'] ?? 'OPEN').toString().toUpperCase();
    final String itemId = item['id'].toString();
    final String? imageUrl = item['image_url']?.toString();

    final Color typeColor = itemType == 'found' ? Colors.green : Colors.orange;
    final Color typeBackgroundColor = itemType == 'found'
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFF3E0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: const Color(0xFF424242),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image
            Hero(
              tag: 'item-${item['id']}',
              child: Container(
                height: 400,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  image: (imageUrl != null && imageUrl.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (imageUrl == null || imageUrl.isEmpty)
                    ? const Icon(Icons.image, size: 80, color: Colors.grey)
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: typeBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: typeColor, width: 1.5),
                    ),
                    child: Text(
                      itemType.toUpperCase(),
                      style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    itemName,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Report Details",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.tag_outlined, "Item ID", itemId),
                  _buildInfoRow(
                    Icons.description_outlined,
                    "Description",
                    description,
                  ),
                  _buildInfoRow(
                    Icons.category_outlined,
                    "Type",
                    itemType.toUpperCase(),
                  ),
                  _buildInfoRow(Icons.info_outlined, "Status", status),
                  _buildInfoRow(Icons.category_outlined, "Category", category),
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    "Location",
                    location,
                  ),
                  _buildInfoRow(
                    Icons.person_outlined,
                    "Submitted By",
                    submittedBy,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF607D8B), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
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
