import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/property_assignment_model.dart';
import '../services/firebase_service.dart';

class PropertyAssignmentRepository {
  final FirebaseService _firebase = FirebaseService();

  Future<void> create(PropertyAssignmentModel assignment) async {
    await _firebase.propertyAssignmentsCollection
        .doc(assignment.assignmentId)
        .set(assignment.toMap());
  }

  Stream<List<PropertyAssignmentModel>> streamInvolving(String userId) {
    return Stream.multi((controller) {
      final subs = [
        _firebase.propertyAssignmentsCollection
            .where('requesterId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .listen(
                (s) => controller.add(s.docs
                    .map((doc) => PropertyAssignmentModel.fromMap(
                        doc.data() as Map<String, dynamic>, doc.id))
                    .toList()),
                onError: controller.addError),
        _firebase.propertyAssignmentsCollection
            .where('targetUserId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .listen(
                (s) => controller.add(s.docs
                    .map((doc) => PropertyAssignmentModel.fromMap(
                        doc.data() as Map<String, dynamic>, doc.id))
                    .toList()),
                onError: controller.addError),
      ];
      controller.onCancel = () {
        for (final sub in subs) {
          sub.cancel();
        }
      };
    });
  }

  Stream<List<PropertyAssignmentModel>> streamByProperty(String propertyId) {
    return _firebase.propertyAssignmentsCollection
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                PropertyAssignmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> update(String assignmentId, Map<String, dynamic> data) async {
    await _firebase.propertyAssignmentsCollection.doc(assignmentId).update(data);
  }
}

final propertyAssignmentRepositoryProvider = Provider<PropertyAssignmentRepository>((ref) {
  return PropertyAssignmentRepository();
});