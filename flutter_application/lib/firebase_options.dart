// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        return ios;
      case TargetPlatform.macOS:
        return macos;
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
    apiKey: 'AIzaSyAdHJI6BGdRLthHM3IoqgxzwXj2c9LwTK4',
    appId: '1:286560292977:web:9aa4d1c4d7440fc5bbcbd0',
    messagingSenderId: '286560292977',
    projectId: 'ku-cupid-storage',
    authDomain: 'ku-cupid-storage.firebaseapp.com',
    storageBucket: 'ku-cupid-storage.appspot.com',
    measurementId: 'G-HCL49YZMMP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBQgiWbKBD-J9f8UeGWE0K7gxGne8hFrNY',
    appId: '1:286560292977:android:02600c38926596afbbcbd0',
    messagingSenderId: '286560292977',
    projectId: 'ku-cupid-storage',
    storageBucket: 'ku-cupid-storage.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBVuhEhrbopH2qqMC_TabyVzpCkLi1eLSA',
    appId: '1:286560292977:ios:bd29c51f58d3f1d2bbcbd0',
    messagingSenderId: '286560292977',
    projectId: 'ku-cupid-storage',
    storageBucket: 'ku-cupid-storage.appspot.com',
    iosBundleId: 'com.example.flutterApplication',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBVuhEhrbopH2qqMC_TabyVzpCkLi1eLSA',
    appId: '1:286560292977:ios:86e7e34a08533ec8bbcbd0',
    messagingSenderId: '286560292977',
    projectId: 'ku-cupid-storage',
    storageBucket: 'ku-cupid-storage.appspot.com',
    iosBundleId: 'com.example.flutterApplication.RunnerTests',
  );
}
