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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBzySwdVUHOxcVOj2YEfWhQI8LgRSjtdqk',
    appId: '1:882165361269:android:85ec0b0eb69510a083263c',
    messagingSenderId: '882165361269',
    projectId: 'mahek-cafe',
    storageBucket: 'mahek-cafe.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBzySwdVUHOxcVOj2YEfWhQI8LgRSjtdqk',
    appId: '1:882165361269:web:YOUR_WEB_APP_ID', // Replace with your actual Web App ID
    messagingSenderId: '882165361269',
    projectId: 'mahek-cafe',
    authDomain: 'mahek-cafe.firebaseapp.com',
    storageBucket: 'mahek-cafe.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBzySwdVUHOxcVOj2YEfWhQI8LgRSjtdqk',
    appId: '1:882165361269:ios:YOUR_IOS_APP_ID', // Replace with your actual iOS App ID
    messagingSenderId: '882165361269',
    projectId: 'mahek-cafe',
    storageBucket: 'mahek-cafe.firebasestorage.app',
    iosBundleId: 'com.example.mahek_cafe', // Use your actual bundle ID
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBzySwdVUHOxcVOj2YEfWhQI8LgRSjtdqk',
    appId: '1:882165361269:macos:YOUR_MACOS_APP_ID', // Replace with your actual macOS App ID
    messagingSenderId: '882165361269',
    projectId: 'mahek-cafe',
    storageBucket: 'mahek-cafe.firebasestorage.app',
    iosBundleId: 'com.example.mahek_cafe', // Use your actual bundle ID
  );
}