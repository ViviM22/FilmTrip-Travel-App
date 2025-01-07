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
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyDz0Pb3EctH7Yi1nf9oLzI-dgnFj2U7h4',
    appId: '1:850925604442:web:1cb99ef5103e64c4a5263',
    messagingSenderId: '850925604442',
    projectId: 'travel-app-3b4b4',
    authDomain: 'travel-app-3b4a4.firebaseapp.com',
    storageBucket: 'travel-app-3b4a4.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAbCk-TzycvtOApNzhjvjFA1VlmlRHkNY',
    appId: '1:850925604442:android:81e290f341f12d84a5263',
    messagingSenderId: '850925604442',
    projectId: 'travel-app-3b4b4',
    storageBucket: 'travel-app-3b4a4.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBJ-P97AEcicEEJ4ITBuEXKOiS78fQEms',
    appId: '1:850925604442:ios:7a5beb0b99e8aef4a5263',
    messagingSenderId: '850925604442',
    projectId: 'travel-app-3b4b4',
    storageBucket: 'travel-app-3b4a4.firebasestorage.app',
    iosBundleId: 'com.example.testapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBJ-P97AEcicEEJ4ITBuEXKOWS78fQEms',
    appId: '1:850925604442:ios:7a5beb0b989e8ef4a5263',
    messagingSenderId: '85092560442',
    projectId: 'travel-app-3b4b4',
    storageBucket: 'travel-app-3b4a4.firebasestorage.app',
    iosBundleId: 'com.example.testapp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDz0Pb3EctH7Yi1nf9oLpI-dgnFj2U7h4',
    appId: '1:850925604442:web:727f476f39ff87e4a5263',
    messagingSenderId: '85092560442',
    projectId: 'travel-app-3b4b4',
    authDomain: 'travel-app-3b4a4.firebaseapp.com',
    storageBucket: 'travel-app-3b4a4.firebasestorage.app',
  );
}