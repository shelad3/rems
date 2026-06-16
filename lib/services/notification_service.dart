import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firestore_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {},
    );

    _initialized = true;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'rent_reminders',
      'Rent Reminders',
      channelDescription: 'Notifications for upcoming rent payments',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> scheduleRentReminders() async {
    final firestore = FirestoreService.instance;
    final leasesSnapshot = await firestore.db.collection('leases').get();
    final leases = leasesSnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    }).toList();

    for (final lease in leases) {
      final endDate =
          DateTime.parse(lease['endDate'] as String);
      final daysUntilEnd = DateTime.now().difference(endDate).inDays;

      if (daysUntilEnd <= 0 && daysUntilEnd >= -5) {
        final tenantName = lease['tenantName'] as String? ?? 'Tenant';
        final propertyName =
            lease['propertyName'] as String? ?? 'Property';
        final rentAmount =
            (lease['rentAmount'] as num?)?.toDouble() ?? 0;

        await showNotification(
          id: lease['id'].hashCode,
          title: 'Rent Reminder',
          body: '$tenantName - \$${rentAmount.toStringAsFixed(0)} due for $propertyName',
        );
      }
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
