import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/owner.dart';
import '../services/firestore_service.dart';

class OwnerProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;
  List<Owner> _owners = [];
  bool _isLoading = false;

  List<Owner> get owners => _owners;
  bool get isLoading => _isLoading;

  Stream<QuerySnapshot> get ownersStream =>
      _firestore.db.collection('owners').snapshots();

  Future<void> loadOwners() async {
    _isLoading = true;
    notifyListeners();
    final snapshot = await _firestore.db.collection('owners').get();
    _owners = snapshot.docs
        .map((doc) =>
            Owner.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addOwner(Owner owner) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    await _firestore.db.collection('owners').doc(id.toString()).set(
      owner.toFirestoreMap(),
    );
    await loadOwners();
    return id;
  }

  Future<void> updateOwner(Owner owner) async {
    await _firestore.db
        .collection('owners')
        .doc(owner.id!.toString())
        .update(owner.toFirestoreMap());
    await loadOwners();
  }

  Future<void> deleteOwner(int id) async {
    await _firestore.db.collection('owners').doc(id.toString()).delete();
    await loadOwners();
  }

  Owner? getOwnerById(int id) {
    try {
      return _owners.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }
}
