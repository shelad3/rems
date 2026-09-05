import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        return web;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAjkrmDrNBiNLXozr1gL1OANVJoZD4ofdc',
    appId: '1:933865910240:android:c6efb58a3a430f5841c585',
    messagingSenderId: '933865910240',
    projectId: 'rems-2026',
    storageBucket: 'rems-2026.firebasestorage.app',
  );

  // iOS / web / macos / windows / linux configs must be added after the
  // corresponding platform config files (GoogleService-Info.plist, web app
  // credentials) are generated from the Firebase console. The values below are
  // intentional placeholders matching the shared project so Firebase Core
  // initializes on all platforms once filled in.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAjkrmDrNBiNLXozr1gL1OANVJoZD4ofdc',
    appId: '1:933865910240:ios:PLACEHOLDER',
    messagingSenderId: '933865910240',
    projectId: 'rems-2026',
    storageBucket: 'rems-2026.firebasestorage.app',
    iosBundleId: 'com.nativecodex.rems',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAjkrmDrNBiNLXozr1gL1OANVJoZD4ofdc',
    appId: '1:933865910240:web:PLACEHOLDER',
    messagingSenderId: '933865910240',
    projectId: 'rems-2026',
    storageBucket: 'rems-2026.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAjkrmDrNBiNLXozr1gL1OANVJoZD4ofdc',
    appId: '1:933865910240:ios:PLACEHOLDER',
    messagingSenderId: '933865910240',
    projectId: 'rems-2026',
    storageBucket: 'rems-2026.firebasestorage.app',
    iosBundleId: 'com.nativecodex.rems',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAjkrmDrNBiNLXozr1gL1OANVJoZD4ofdc',
    appId: '1:933865910240:web:PLACEHOLDER',
    messagingSenderId: '933865910240',
    projectId: 'rems-2026',
    storageBucket: 'rems-2026.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyAjkrmDrNBiNLXozr1gL1OANVJoZD4ofdc',
    appId: '1:933865910240:web:PLACEHOLDER',
    messagingSenderId: '933865910240',
    projectId: 'rems-2026',
    storageBucket: 'rems-2026.firebasestorage.app',
  );
}
