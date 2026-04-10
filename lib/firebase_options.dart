// File: lib/firebase_options.dart
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
        return web;
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
    apiKey: 'AIzaSyCh-PfaGrnn0RE3iYYcuZkP26ORqALRhv4',
    appId: '1:634536402530:web:7016888c804af5913b7b3b',
    messagingSenderId: '634536402530',
    projectId: 'congrowing',
    authDomain: 'congrowing.firebaseapp.com',
    storageBucket: 'congrowing.firebasestorage.app',
    measurementId: 'G-J1JJLXB063',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDWm02v_IGMtmuxb8x7ZfIwWd5blCBL4nw',
    appId: '1:634536402530:android:3f1f2386598fbb4c3b7b3b',
    messagingSenderId: '634536402530',
    projectId: 'congrowing',
    storageBucket: 'congrowing.firebasestorage.app',
  );
}
