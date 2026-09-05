import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/maintenance_repository.dart';
import '../../../data/models/maintenance_ticket_model.dart';

class MaintenanceNotifier extends ChangeNotifier {
  final MaintenanceRepository _repository;
  bool _loading = false;
  String? _error;

  MaintenanceNotifier(this._repository);

  bool get loading => _loading;
  String? get error => _error;

  Future<void> createTicket(MaintenanceTicketModel ticket) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.createTicket(ticket);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    try {
      await _repository.updateTicket(ticketId, {
        'status': status,
        if (status == 'resolved') 'resolvedAt': DateTime.now(),
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

final maintenanceProvider = ChangeNotifierProvider<MaintenanceNotifier>((ref) {
  return MaintenanceNotifier(ref.read(maintenanceRepositoryProvider));
});
