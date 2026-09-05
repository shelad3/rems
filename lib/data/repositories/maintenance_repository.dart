import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/maintenance_ticket_model.dart';
import '../services/firebase_service.dart';

class MaintenanceRepository {
  final FirebaseService _firebase = FirebaseService();

  Future<void> createTicket(MaintenanceTicketModel ticket) async {
    await _firebase.maintenanceTicketsCollection.doc(ticket.ticketId).set(ticket.toMap());
  }

  Stream<List<MaintenanceTicketModel>> getTicketsByTenant(String tenantId) {
    return _firebase.maintenanceTicketsCollection
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceTicketModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<MaintenanceTicketModel>> getTicketsByProperty(String propertyId) {
    return _firebase.maintenanceTicketsCollection
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceTicketModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<MaintenanceTicketModel>> getOpenTicketsByProperty(String propertyId) {
    return _firebase.maintenanceTicketsCollection
        .where('propertyId', isEqualTo: propertyId)
        .where('status', whereIn: ['open', 'in_progress'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceTicketModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> updateTicket(String ticketId, Map<String, dynamic> data) async {
    await _firebase.maintenanceTicketsCollection.doc(ticketId).update(data);
  }
}

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepository();
});
