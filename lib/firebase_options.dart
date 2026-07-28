// File generated manually to bypass CLI path issues.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions have not been configured for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA0xbhahnIoTqAna_Vto0YabkiiT1fZRbY',
    appId: '1:143702006249:web:b7aef0b543bacaed109378',
    messagingSenderId: '143702006249',
    projectId: 'cookbook-app-95707',
    authDomain: 'cookbook-app-95707.firebaseapp.com',
    storageBucket: 'cookbook-app-95707.firebasestorage.app',
  );
}