// firebase_options.dart
// AUTO-GENERATED for SafeLink mock testing.
//
// IMPORTANT: For production / real device builds you must replace this file
// with the output of `flutterfire configure`, which generates proper
// google-services.json (Android) and GoogleService-Info.plist (iOS) files.
// The values below are taken from the existing React-Native project config and
// work for Firestore read/write during mock testing on any platform.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
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
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  // Shared base config — same project for all platforms during mock testing.
  static const FirebaseOptions _base = FirebaseOptions(
    apiKey: 'AIzaSyBYG_Ct43Xokf8f14XH5mw5n_Bu9jskySg',
    appId: '1:130637803692:web:8ae872344885ffd9f02f09',
    messagingSenderId: '130637803692',
    projectId: 'connect-0-app',
    storageBucket: 'connect-0-app.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBYG_Ct43Xokf8f14XH5mw5n_Bu9jskySg',
    appId: '1:130637803692:web:8ae872344885ffd9f02f09',
    messagingSenderId: '130637803692',
    projectId: 'connect-0-app',
    storageBucket: 'connect-0-app.firebasestorage.app',
    authDomain: 'connect-0-app.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBYG_Ct43Xokf8f14XH5mw5n_Bu9jskySg',
    appId: '1:130637803692:android:8ae872344885ffd9f02f09',
    messagingSenderId: '130637803692',
    projectId: 'connect-0-app',
    storageBucket: 'connect-0-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBBkGTlGATFToi_ZKNMwYVfePxkzq449S4',
    appId: '1:130637803692:ios:859a04eb24b124c3f02f09',
    messagingSenderId: '130637803692',
    projectId: 'connect-0-app',
    storageBucket: 'connect-0-app.firebasestorage.app',
    iosBundleId: 'com.Siddharth.SafeLink',
    iosClientId: '130637803692-p9qbueo75kmdob83da937ke1c6ieo9cp.apps.googleusercontent.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBBkGTlGATFToi_ZKNMwYVfePxkzq449S4',
    appId: '1:130637803692:ios:859a04eb24b124c3f02f09',
    messagingSenderId: '130637803692',
    projectId: 'connect-0-app',
    storageBucket: 'connect-0-app.firebasestorage.app',
    iosBundleId: 'com.Siddharth.SafeLink',
    iosClientId: '130637803692-p9qbueo75kmdob83da937ke1c6ieo9cp.apps.googleusercontent.com',
  );

  static const FirebaseOptions windows = _base;
  static const FirebaseOptions linux = _base;
}
