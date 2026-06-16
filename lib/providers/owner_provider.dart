import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/database_helper.dart';
import '../models/owner.dart';
import '../services/firestore_service.dart';

class OwnerProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
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
    final maps = await _db.queryAll('owners');
    _owners = maps.map((m) => Owner.fromMap(m)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addOwner(Owner owner) async {
    final id = await _db.insert('owners', owner.toMap());
    try {
      await _firestore.db.collection('owners').doc(id.toString()).set({
        ...owner.toFirestoreMap(),
        'oldOwnerId': id,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Firestore addOwner error: $e');
    }
    await loadOwners();
    return id;
  }

  Future<void> updateOwner(Owner owner) async {
    await _db.update('owners', owner.toMap(), owner.id!);
    try {
      await _firestore.db
          .collection('owners')
          .doc(owner.id.toString())
          .update(owner.toFirestoreMap());
    } catch (e) {
      debugPrint('Firestore updateOwner error: $e');
    }
    await loadOwners();
  }

  Future<void> deleteOwner(int id) async {
    await _db.delete('owners', id);
    try {
      await _firestore.db.collection('owners').doc(id.toString()).delete();
    } catch (e) {
      debugPrint('Firestore deleteOwner error: $e');
    }
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
