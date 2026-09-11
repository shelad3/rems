import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._();
  factory FirebaseService() => _instance;
  FirebaseService._();

  bool _initialized = false;

  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;
  FirebaseMessaging get messaging => FirebaseMessaging.instance;

  Future<void> initialize() async {
    if (_initialized) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    try {
      await FirebaseAppCheck.instance
          .activate(
            androidProvider: kDebugMode
                ? AndroidProvider.debug
                : AndroidProvider.playIntegrity,
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}

    _initialized = true;

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    await _initRemoteConfig();
  }

  Future<void> _initRemoteConfig() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setDefaults(const {
      'premium_enabled': true,
      'ads_enabled': true,
      'max_free_properties': 1,
    });
    try {
      await remoteConfig.fetchAndActivate();
    } catch (_) {}
  }

  CollectionReference get usersCollection => firestore.collection('users');
  CollectionReference get propertiesCollection => firestore.collection('properties');
  CollectionReference get buildingsCollection => firestore.collection('buildings');
  CollectionReference get unitsCollection => firestore.collection('units');
  CollectionReference get accessRequestsCollection => firestore.collection('access_requests');
  CollectionReference get leasesCollection => firestore.collection('leases');
  CollectionReference get paymentsCollection => firestore.collection('payments');
  CollectionReference get maintenanceTicketsCollection => firestore.collection('maintenance_tickets');
  CollectionReference get notificationsCollection => firestore.collection('notifications');
  CollectionReference get announcementsCollection => firestore.collection('announcements');
  CollectionReference get staffCollection => firestore.collection('staff');
  CollectionReference get auditLogsCollection => firestore.collection('audit_logs');
  CollectionReference get subscriptionsCollection => firestore.collection('subscriptions');
  CollectionReference get messagesCollection => firestore.collection('messages');
  CollectionReference get walletsCollection => firestore.collection('wallets');
  CollectionReference get walletTransactionsCollection => firestore.collection('wallet_transactions');
  CollectionReference get rentInvoicesCollection => firestore.collection('rent_invoices');
  CollectionReference get caretakerApplicationsCollection => firestore.collection('caretaker_applications');
  CollectionReference get propertyAssignmentsCollection => firestore.collection('property_assignments');

  Future<String> uploadFile(String path, String fileName, Uint8List bytes) async {
    final ref = storage.ref().child('$path/$fileName');
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }

  Future<String> uploadFileFromPath(String path, String fileName, String localPath) async {
    final ref = storage.ref().child('$path/$fileName');
    await ref.putFile(io.File(localPath));
    return await ref.getDownloadURL();
  }
}
