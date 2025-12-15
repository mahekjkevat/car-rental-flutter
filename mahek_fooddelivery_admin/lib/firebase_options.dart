import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // NOTE: Web settings must be configured separately in your Firebase project.
      // This is a placeholder for web configuration.
      throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for web - '
              'you can reconfigure this by running the FlutterFire CLI command: '
              '`flutter pub run flutter fire configure`.'
      );
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
                'you can reconfigure this by running the FlutterFire CLI command: '
                '`flutter pub run flutter fire configure`.'
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
            'DefaultFirebaseOptions have not been configured for linux - '
                'you can reconfigure this by running the FlutterFire CLI command: '
                '`flutter pub run flutter fire configure`.'
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBzySwdVUHOxcVOj2YEfWhQI8LgRSjtdqk',
    // UPDATED: Using the App ID for the 'mahek_fooddelivery_admin' package
    appId: '1:882165361269:android:5f9442a271f35ccc83263c',
    messagingSenderId: '882165361269',
    projectId: 'mahek-cafe',
    storageBucket: 'mahek-cafe.firebasestorage.app',
  );

  // NOTE: iOS configuration is inferred from the Android configuration but
  // typically requires a separate 'GoogleService-Info.plist' file and bundle ID
  // matching the Android configuration.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBzySwdVUHOxcVOj2YEfWhQI8LgRSjtdqk',
    // Note: iOS App ID needs to be registered with the corresponding Bundle ID in Firebase Console.
    // Reusing the messagingSenderId as the iOS client App ID is not explicitly provided for the Admin app.
    appId: '1:882165361269:ios:37fd6eae72eee05883263c',
    messagingSenderId: '882165361269',
    projectId: 'mahek-cafe',
    storageBucket: 'mahek-cafe.firebasestorage.app',
    // UPDATED: Assuming the Admin iOS Bundle ID would match the Android package name context.
    iosBundleId: 'com.example.mahek_fooddelivery_admin',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBzySwdVUHOxcVOj2YEfWhQI8LgRSjtdqk',
    // Placeholder. Verify/Change for macOS client.
    appId: '1:882165361269:ios:37fd6eae72eee05883263c',
    messagingSenderId: '882165361269',
    projectId: 'mahek-cafe',
    storageBucket: 'mahek-cafe.firebasestorage.app',
    // UPDATED: Assuming the Admin macOS Bundle ID would match the Android package name context.
    iosBundleId: 'com.example.mahek_fooddelivery_admin',
  );
}