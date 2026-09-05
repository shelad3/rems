import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class UserRepository {
  final FirebaseService _firebase = FirebaseService();

  Stream<UserModel?> getUserById(String uid) {
    return _firebase.usersCollection.doc(uid).snapshots().map(
      (snapshot) => snapshot.exists
          ? UserModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id)
          : null,
    );
  }

  Future<List<UserModel>> getUsersByRole(String role) async {
    final snapshot = await _firebase.usersCollection
        .where('role', isEqualTo: role)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<List<UserModel>> getUsersByProperty(String propertyId) async {
    final snapshot = await _firebase.usersCollection
        .where('currentPropertyId', isEqualTo: propertyId)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firebase.usersCollection
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Stream<List<UserModel>> streamUsersByRole(String role) {
    return _firebase.usersCollection
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<UserModel>> streamAllUsers() {
    return _firebase.usersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firebase.usersCollection.doc(uid).update(data);
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});
