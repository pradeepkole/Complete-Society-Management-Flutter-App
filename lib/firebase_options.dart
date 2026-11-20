// File generated and updated with official Firebase configuration.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Connected to Firebase project: society-6ad99
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBGIAjXlD2Ui7o4-cVEYaA4fSANP2YUkJI',
    appId: '1:380597262688:web:54675b6a74e6ab31496605',
    messagingSenderId: '380597262688',
    projectId: 'society-6ad99',
    authDomain: 'society-6ad99.firebaseapp.com',
    storageBucket: 'society-6ad99.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBGIAjXlD2Ui7o4-cVEYaA4fSANP2YUkJI',
    appId: '1:380597262688:android:54675b6a74e6ab31496605',
    messagingSenderId: '380597262688',
    projectId: 'society-6ad99',
    storageBucket: 'society-6ad99.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBGIAjXlD2Ui7o4-cVEYaA4fSANP2YUkJI',
    appId: '1:380597262688:ios:54675b6a74e6ab31496605',
    messagingSenderId: '380597262688',
    projectId: 'society-6ad99',
    storageBucket: 'society-6ad99.firebasestorage.app',
    iosBundleId: 'com.society.housing_society_app',
  );
}
