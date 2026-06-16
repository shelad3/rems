import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';
import '../services/firestore_service.dart';

class TaskProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;
  List<Task> _tasks = [];
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  Future<void> loadTasks({String? status, int? propertyId}) async {
    _isLoading = true;
    notifyListeners();
    final snapshot = await _firestore.db.collection('tasks').get();
    _tasks = snapshot.docs
        .map((doc) =>
            Task.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    if (status != null) {
      _tasks = _tasks.where((t) => t.status == status).toList();
    }
    if (propertyId != null) {
      _tasks = _tasks.where((t) => t.propertyId == propertyId).toList();
    }
    _isLoading = false;
    notifyListeners();
  }

  List<Task> searchTasks(String query) {
    final q = query.toLowerCase();
    return _tasks.where((t) =>
      t.title.toLowerCase().contains(q) ||
      t.description.toLowerCase().contains(q)
    ).toList();
  }

  Future<void> addTask(Task task) async {
    final id = DateTime.now().millisecondsSinceEpoch;
    await _firestore.db.collection('tasks').doc(id.toString()).set(
      task.toFirestoreMap(),
    );
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await _firestore.db
        .collection('tasks')
        .doc(task.id!.toString())
        .update(task.toFirestoreMap());
    await loadTasks();
  }

  Future<void> completeTask(int id) async {
    await _firestore.db.collection('tasks').doc(id.toString()).update({
      'status': 'Completed',
      'completedAt': DateTime.now().toIso8601String(),
    });
    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await _firestore.db.collection('tasks').doc(id.toString()).delete();
    await loadTasks();
  }

  int get pendingCount => _tasks.where((t) => t.status == 'Pending').length;
  int get overdueCount => _tasks.where((t) {
        if (t.status == 'Completed' || t.dueDate == null) return false;
        return t.dueDate!.isBefore(DateTime.now());
      }).length;
}
