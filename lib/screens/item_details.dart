import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  late Future<String?> _userClaimStatusFuture;
  late Future<bool> _hasApprovedClaimFuture;
  final TextEditingController _claimMessageController = TextEditingController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshData();

    // Refresh data every 3 seconds to check for admin updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _refreshData();
        });
      }
    });
  }

  void _refreshData() {
    _userClaimStatusFuture = _getUserClaimStatus();
    _hasApprovedClaimFuture = _hasApprovedClaim();
  }

  @override
  void dispose() {
    _claimMessageController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getCategoryName(),
      builder: (context, categorySnapshot) {
        return FutureBuilder<String>(
          future: _getSubmittedByName(widget.item['user_id']),
          builder: (context, submittedBySnapshot) {
            return FutureBuilder<String?>(
              future: _userClaimStatusFuture,
              builder: (context, claimSnapshot) {
                return FutureBuilder<bool>(
                  future: _hasApprovedClaimFuture,
                  builder: (context, approvedSnapshot) {
                    return _buildDetails(
                      context,
                      categorySnapshot.data ?? 'Uncategorized',
                      submittedBySnapshot.data ?? 'Unknown',
                      claimSnapshot.data,
                      approvedSnapshot.data ?? false,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<bool> _hasApprovedClaim() async {
    try {
      final response = await supabase
          .from('claims')
          .select('id')
          .eq('item_id', widget.item['id'])
          .eq('status', 'approved')
          .maybeSingle();

      final hasApproved = response != null;
      debugPrint(
        'DEBUG: Checking approved claims for item ${widget.item['id']}',
      );
      debugPrint('DEBUG: Has approved claim: $hasApproved');
      return hasApproved;
    } catch (e) {
      debugPrint('Error checking approved claims: $e');
      return false;
    }
  }

  Future<String?> _getUserClaimStatus() async {
    final user = supabase.auth.currentUser;

    // Return null if user is not logged in or is guest
    if (user == null || user.email == null || user.email!.isEmpty) return null;

    try {
      final response = await supabase
          .from('claims')
          .select('id, status')
          .eq('item_id', widget.item['id'])
          .eq('claimant_id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return response['status'] as String?;
    } catch (e) {
      debugPrint('Error checking claim status: $e');
      return null;
    }
  }

  Future<void> _submitClaim(BuildContext context) async {
    final user = supabase.auth.currentUser;

    // Check if user is not logged in or is a guest
    if (user == null || user.email == null || user.email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to claim an item')),
      );
      return;
    }

    debugPrint('Submitting claim for user: ${user.email}');

    try {
      final claimResponse = await supabase
          .from('claims')
          .insert({
            'item_id': widget.item['id'],
            'claimant_id': user.id,
            'claim_details': _claimMessageController.text.isNotEmpty
                ? _claimMessageController.text
                : null,
            'status': 'pending',
          })
          .select()
          .single();

      // Notify admin about the new claim
      await _notifyAdminOfNewClaim(user.id, claimResponse['id']);

      _claimMessageController.clear();

      if (context.mounted) {
        setState(() {
          _userClaimStatusFuture = _getUserClaimStatus();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Claim submitted successfully! Awaiting approval.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on PostgrestException catch (e) {
      debugPrint('PostgreSQL Error Code: ${e.code}');
      debugPrint('PostgreSQL Error Message: ${e.message}');
      debugPrint('PostgreSQL Error Details: ${e.details}');
      debugPrint('Current User ID: ${user.id}');
      debugPrint('Item ID: ${widget.item['id']}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting claim: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting claim: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error submitting claim: $e');
    }
  }

  Future<void> _notifyAdminOfNewClaim(
    dynamic claimantId,
    dynamic claimId,
  ) async {
    try {
      // Get claimant user data
      final claimantData = await supabase
          .from('users')
          .select('first_name, last_name, email')
          .eq('id', claimantId)
          .single();

      final claimantName =
          '${claimantData['first_name']} ${claimantData['last_name']}';
      final claimantEmail = claimantData['email'];

      // Get item data
      final itemData = await supabase
          .from('items')
          .select('title, type, location')
          .eq('id', widget.item['id'])
          .single();

      // Get item owner data
      final ownerData = await supabase
          .from('users')
          .select('email')
          .eq('id', widget.item['user_id'])
          .single();

      // Create admin notification in database
      await supabase.from('notifications').insert({
        'type': 'new_claim',
        'title': 'New Claim Submitted',
        'message':
            '$claimantName has submitted a claim for "${itemData['title']}" (${itemData['type'].toString().toUpperCase()})',
        'claim_id': claimId,
        'item_id': widget.item['id'],
        'claimant_id': claimantId,
        'claimant_email': claimantEmail,
        'item_owner_email': ownerData['email'],
        'status': 'unread',
      });

      debugPrint('Admin notification created for claim: $claimId');
    } catch (e) {
      debugPrint('Error creating admin notification: $e');
      // Don't fail the claim submission if notification fails
    }
  }

  void _showClaimDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Claim Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to claim this item?',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add a message (optional):',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _claimMessageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'E.g., "This is my laptop. I have proof of purchase..."',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _submitClaim(context);
            },
            child: const Text('Submit Claim'),
          ),
        ],
      ),
    );
  }

  Future<String> _getCategoryName() async {
    try {
      final categoryId = widget.item['category_id'];
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
    String? claimStatus,
    bool hasApprovedClaim,
  ) {
    debugPrint('Item data: ${widget.item}');
    final String itemName = (widget.item['title'] ?? 'Unnamed Item').toString();
    final String description =
        (widget.item['description'] ?? 'No description provided.').toString();
    final String location = (widget.item['location'] ?? 'Not specified')
        .toString();
    final String itemType = (widget.item['type'] ?? 'unknown')
        .toString()
        .toLowerCase();
    final String status = (widget.item['status'] ?? 'OPEN')
        .toString()
        .toUpperCase();
    final String itemId = widget.item['id'].toString();
    final String? imageUrl = widget.item['image_url']?.toString();

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
              tag: 'item-${widget.item['id']}',
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
                  const SizedBox(height: 24),
                  _buildClaimButton(context, claimStatus, hasApprovedClaim),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimButton(
    BuildContext context,
    String? claimStatus,
    bool hasApprovedClaim,
  ) {
    debugPrint(
      'DEBUG: _buildClaimButton called with hasApprovedClaim: $hasApprovedClaim, claimStatus: $claimStatus',
    );

    final user = supabase.auth.currentUser;

    // Check if user is not logged in or is a guest (no email)
    final isGuest = user == null || user.email == null || user.email!.isEmpty;
    final isOwnItem = user != null && user.id == widget.item['user_id'];

    if (isGuest) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue),
        ),
        child: const Text(
          'Please login to claim this item',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      );
    }

    if (isOwnItem) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Text(
          'This is your item',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      );
    }

    if (hasApprovedClaim) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Text(
          'Item Already Claimed',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      );
    }

    if (claimStatus == 'pending') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_top, color: Colors.orange, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Claim Pending - Awaiting Approval',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (claimStatus == 'approved') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Claim Approved',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (claimStatus == 'rejected') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Claim Rejected',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showClaimDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003366),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.touch_app),
        label: const Text(
          'Claim This Item',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
