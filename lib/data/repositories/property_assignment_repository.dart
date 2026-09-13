import 'dart:async';
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
    late final StreamController<List<PropertyAssignmentModel>> controller;
    List<PropertyAssignmentModel> asRequester = [];
    List<PropertyAssignmentModel> asTarget = [];
    late final StreamSubscription<dynamic> subR;
    late final StreamSubscription<dynamic> subT;
    bool closed = false;

    List<PropertyAssignmentModel> merge() {
      final map = <String, PropertyAssignmentModel>{};
      for (final a in asRequester) {
        map[a.assignmentId] = a;
      }
      for (final a in asTarget) {
        map.putIfAbsent(a.assignmentId, () => a);
      }
      final list = map.values.toList()
        ..sort((x, y) => y.createdAt.compareTo(x.createdAt));
      return list;
    }

    controller = StreamController<List<PropertyAssignmentModel>>(
      onListen: () {
        subR = _firebase.propertyAssignmentsCollection
            .where('requesterId', isEqualTo: userId)
            .snapshots()
            .listen(
                (s) {
                  asRequester = s.docs
                      .map((doc) => PropertyAssignmentModel.fromMap(
                          doc.data() as Map<String, dynamic>, doc.id))
                      .toList();
                  if (!closed) controller.add(merge());
                },
                onError: (e) {
                  if (!closed) controller.addError(e);
                });
        subT = _firebase.propertyAssignmentsCollection
            .where('targetUserId', isEqualTo: userId)
            .snapshots()
            .listen(
                (s) {
                  asTarget = s.docs
                      .map((doc) => PropertyAssignmentModel.fromMap(
                          doc.data() as Map<String, dynamic>, doc.id))
                      .toList();
                  if (!closed) controller.add(merge());
                },
                onError: (e) {
                  if (!closed) controller.addError(e);
                });
      },
      onCancel: () {
        closed = true;
        subR.cancel();
        subT.cancel();
      },
    );
    return controller.stream;
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