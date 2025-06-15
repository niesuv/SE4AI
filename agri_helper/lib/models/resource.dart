import 'package:cloud_firestore/cloud_firestore.dart';

class Resource {
  final String id;
  final String name;
  final String userId;
  final DateTime startAt;
  final List<Map<String, dynamic>> actions;

  Resource({
    required this.id,
    required this.name,
    required this.userId,
    required this.startAt,
    required this.actions,
  });

  factory Resource.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Resource(
      id: doc.id,
      name: data['name'] ?? '',
      userId: data['userId'] ?? '',
      startAt: (data['startAt'] as Timestamp).toDate(),
      actions: List<Map<String, dynamic>>.from(data['actions'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'userId': userId,
      'startAt': Timestamp.fromDate(startAt),
      'actions': actions,
    };
  }
}
