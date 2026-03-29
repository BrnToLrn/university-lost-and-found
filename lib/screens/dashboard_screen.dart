import 'package:flutter/material.dart';
import '../main.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('University Lost & Found'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => supabase.auth.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('items').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text('No items found.'));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  // Proves Storage: Shows an image from your bucket URL
                  leading: item['image_url'] != null
                      ? Image.network(
                          item['image_url'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image),
                  title: Text(item['item_name'] ?? 'Item'),
                  subtitle: Text(item['description'] ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
