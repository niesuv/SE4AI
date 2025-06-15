// lib/pages/resource_detail/resource_detail_page.dart

import 'package:agri_helper/services/FireStoreService.dart';
import 'package:agri_helper/services/NotificationService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/resource.dart';

class ResourceDetailPage extends StatefulWidget {
  final Resource resource;

  const ResourceDetailPage({super.key, required this.resource});

  @override
  State<ResourceDetailPage> createState() => _ResourceDetailPageState();
}

class _ResourceDetailPageState extends State<ResourceDetailPage> {
  final FirestoreService firestoreService = FirestoreService();
  late Resource editable;
  final _formKey = GlobalKey<FormState>();

  final _actionNameController = TextEditingController();
  final _actionContentController = TextEditingController();
  DateTime? _selectedStartAt;
  bool _shouldNotify = false;

  @override
  void initState() {
    super.initState();
    editable = Resource(
      id: widget.resource.id,
      name: widget.resource.name,
      startAt: widget.resource.startAt,
      userId: widget.resource.userId,
      actions: List<Map<String, dynamic>>.from(widget.resource.actions),
    );
  }

  void _addAction() async {
    if (_actionNameController.text.isEmpty || _selectedStartAt == null) return;

    final shouldNotify = _shouldNotify;
    final newAction = {
      'name': _actionNameController.text,
      'startAt': _selectedStartAt!,
      'content': _actionContentController.text,
    };

    if (shouldNotify) {
      await NotificationService.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: newAction['name'] as String,
        body: newAction['content'] as String? ?? '',
        scheduledTime: newAction['startAt'] as DateTime,
      );
    }

    setState(() {
      editable.actions.add(newAction);
      _actionNameController.clear();
      _actionContentController.clear();
      _selectedStartAt = null;
      _shouldNotify = false;
    });
  }


  void _removeAction(int index) {
    setState(() => editable.actions.removeAt(index));
  }

  Future<void> _save() async {
    await firestoreService.saveResource(editable);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(editable.name),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child:
                  editable.actions.isEmpty
                      ? Center(
                        child: Text(
                          'Chưa có hành động nào.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                      : ListView.separated(
                        itemCount: editable.actions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final action = editable.actions[index];
                          final startAt =
                              action['startAt'] is Timestamp
                                  ? (action['startAt'] as Timestamp).toDate()
                                  : action['startAt'] as DateTime;

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                action['name'] ?? '',
                                style: theme.textTheme.titleMedium,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat.yMd().add_jm().format(startAt),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if ((action['content'] ?? '').isNotEmpty)
                                    Text(
                                      action['content'],
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeAction(index),
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 100), // avoid overlap with FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.save),
        label: const Text('Lưu lại'),
      ),
      bottomSheet: Container(
        color: theme.colorScheme.surface,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thêm hành động mới',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _actionNameController,
                decoration: InputDecoration(
                  labelText: 'Tên hành động',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.task_alt_outlined),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final now = DateTime.now();
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now,
                    lastDate: DateTime(now.year + 5),
                  );
                  if (pickedDate == null) return;

                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(now),
                  );
                  if (pickedTime == null) return;

                  setState(() {
                    _selectedStartAt = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                  });
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Thời gian bắt đầu',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.access_time),
                  ),
                  child: Text(
                    _selectedStartAt != null
                        ? DateFormat.yMd().add_jm().format(_selectedStartAt!)
                        : 'Chọn thời gian',
                    style:
                        _selectedStartAt != null
                            ? null
                            : TextStyle(color: theme.hintColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _actionContentController,
                decoration: InputDecoration(
                  labelText: 'Nội dung chi tiết',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _shouldNotify,
                onChanged: (value) {
                  setState(() => _shouldNotify = value ?? false);
                },
                title: const Text("Nhắc tôi bằng thông báo"),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _addAction,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm hành động'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
