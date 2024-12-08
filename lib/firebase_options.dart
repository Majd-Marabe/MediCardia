// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDGdj78Dpqa7YKTj3flLtewNRnTVUaJTiM',
    appId: '1:645330668025:web:aae846640ed5ea31ab5528',
    messagingSenderId: '645330668025',
    projectId: 'majd-726c9',
    authDomain: 'majd-726c9.firebaseapp.com',
    storageBucket: 'majd-726c9.firebasestorage.app',
    measurementId: 'G-2CC2LT453B',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCcMHzXz8TVJhQBQqyCy7lAz7zz3-9PZ7U',
    appId: '1:645330668025:android:425d9797d89d0bdaab5528',
    messagingSenderId: '645330668025',
    projectId: 'majd-726c9',
    storageBucket: 'majd-726c9.firebasestorage.app',
  );
}
