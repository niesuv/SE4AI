import 'package:agri_helper/services/FireStoreService.dart';
import 'package:agri_helper/widget/user_resources/ResourceDetailPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/resource.dart';

class ResourceListPage extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final firestore = FirestoreService();

  void _createResource(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tạo tài nguyên mới'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tên tài nguyên',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            icon: const Icon(Icons.add),
            label: const Text('Tạo'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final newResource = Resource(
        id: '',
        name: result,
        userId: userId,
        startAt: DateTime.now(),
        actions: [],
      );

      final newId = await firestore.addResource(newResource);
      final createdResource = await firestore.getResourceById(newId);

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResourceDetailPage(resource: createdResource),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài nguyên của tôi'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createResource(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm'),
      ),
      body: StreamBuilder<List<Resource>>(
        stream: firestore.getResources(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final resources = snapshot.data!;
          if (resources.isEmpty) {
            return Center(
              child: Text(
                'Chưa có tài nguyên nào',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: resources.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final r = resources[i];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResourceDetailPage(resource: r),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.folder, size: 40, color: Colors.green),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.name,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat.yMMMd().add_jm().format(r.startAt),
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
