import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_plan_model.dart';
import '../services/firebase_service.dart';

class SubscriptionRepository {
  final FirebaseService _firebase = FirebaseService();

  Stream<List<SubscriptionPlanModel>> streamPlans() {
    return _firebase.subscriptionsCollection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => SubscriptionPlanModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList(),
    );
  }

  Future<void> createPlan(SubscriptionPlanModel plan) async {
    await _firebase.subscriptionsCollection.doc(plan.planId).set(plan.toMap());
  }

  Future<void> updatePlan(String planId, Map<String, dynamic> data) async {
    await _firebase.subscriptionsCollection.doc(planId).update(data);
  }

  Future<void> deletePlan(String planId) async {
    await _firebase.subscriptionsCollection.doc(planId).delete();
  }
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository();
});