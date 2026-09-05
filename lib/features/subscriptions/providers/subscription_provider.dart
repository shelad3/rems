import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../../../data/services/auth_service.dart';

final isPremiumProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.subscriptionTier == 'premium';
});

final featureFlagProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.fetchAndActivate();
  return {
    'premium_enabled': remoteConfig.getBool('premium_enabled'),
    'max_free_properties': remoteConfig.getInt('max_free_properties'),
    'ads_enabled': remoteConfig.getBool('ads_enabled'),
    'ad_frequency': remoteConfig.getDouble('ad_frequency'),
    'analytics_export_enabled': remoteConfig.getBool('analytics_export_enabled'),
    'multi_property_enabled': remoteConfig.getBool('multi_property_enabled'),
    'smart_notifications_enabled': remoteConfig.getBool('smart_notifications_enabled'),
  };
});

final canUseMultiplePropertiesProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final flags = ref.watch(featureFlagProvider).valueOrNull ?? {};

  if (user?.subscriptionTier == 'premium') return true;
  if (flags['multi_property_enabled'] == true) return true;

  return false;
});
