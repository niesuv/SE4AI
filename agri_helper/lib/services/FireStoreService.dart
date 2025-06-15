import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/resource.dart';

class FirestoreService {
    final _resources = FirebaseFirestore.instance.collection('user_resources');

    Stream<List<Resource>> getResources(String userId) {
        return _resources
            .where('userId', isEqualTo: userId)
            .orderBy('startAt', descending: true)
            .snapshots()
            .map((snap) => snap.docs.map(Resource.fromFirestore).toList());
    }

    /// Save (create or update)
    Future<void> saveResource(Resource resource) async {
        if (resource.id.isEmpty) {
            await _resources.add(resource.toFirestore());
        } else {
            await _resources.doc(resource.id).set(resource.toFirestore());
        }
    }

    /// 🔧 Create only and return the new document id
    Future<String> addResource(Resource resource) async {
        final docRef = await _resources.add(resource.toFirestore());
        return docRef.id;
    }

    Future<void> deleteResource(String id) async {
        await _resources.doc(id).delete();
    }

    Future<Resource> getResourceById(String id) async {
        final doc = await _resources.doc(id).get();
        return Resource.fromFirestore(doc);
    }
}
