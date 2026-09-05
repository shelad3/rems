import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meter_reading_model.dart';
import '../services/firebase_service.dart';

class MeterReadingRepository {
  final FirebaseService _firebase = FirebaseService();

  Future<void> recordReading(MeterReadingModel reading) async {
    await _firebase.firestore
        .collection('meter_readings')
        .doc(reading.readingId)
        .set(reading.toMap());
  }

  Stream<List<MeterReadingModel>> getReadingsByUnit(String unitId, {String? type}) {
    var query = _firebase.firestore
        .collection('meter_readings')
        .where('unitId', isEqualTo: unitId);
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MeterReadingModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<double> getLatestReading(String unitId, String type) async {
    final snapshot = await _firebase.firestore
        .collection('meter_readings')
        .where('unitId', isEqualTo: unitId)
        .where('type', isEqualTo: type)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return 0;
    return (snapshot.docs.first.data()['value'] as num?)?.toDouble() ?? 0;
  }
}

final meterReadingRepositoryProvider = Provider<MeterReadingRepository>((ref) {
  return MeterReadingRepository();
});
