// File generated manually for Web Support

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCo2G1m8rwMZYsV1mhMzuhsJOJY183e3DY',
    appId: '1:897744544653:web:5e4e15dc2d341ff89b93c4',
    messagingSenderId: '897744544653',
    projectId: 'uniti-x-project-management',
    authDomain: 'uniti-x-project-management.firebaseapp.com',
    storageBucket: 'uniti-x-project-management.firebasestorage.app',
    measurementId: 'G-KD2M74J3M6',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCCy5bjmxoD0gLS-QtUdJSYDAcLdOV8EJc',
    appId: '1:897744544653:android:6d6a9f1b48f41c659b93c4',
    messagingSenderId: '897744544653',
    projectId: 'uniti-x-project-management',
    storageBucket: 'uniti-x-project-management.firebasestorage.app',
  );
}
