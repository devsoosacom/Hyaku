import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAB_OLK_K5pLIbOkHAztd5k5-NYi7nJth0',
    appId: '1:215836366665:web:5b41f2f1239ae5e402ec98',
    messagingSenderId: '215836366665',
    projectId: 'hyaku-35692',
    authDomain: 'hyaku-35692.firebaseapp.com',
    storageBucket: 'hyaku-35692.firebasestorage.app',
    measurementId: 'G-2XF6K348BJ',
  );

  // Populated after google-services.json is added
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAB_OLK_K5pLIbOkHAztd5k5-NYi7nJth0',
    appId: '1:215836366665:android:placeholder',
    messagingSenderId: '215836366665',
    projectId: 'hyaku-35692',
    storageBucket: 'hyaku-35692.firebasestorage.app',
  );
}
