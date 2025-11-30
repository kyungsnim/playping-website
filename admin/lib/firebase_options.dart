// Firebase configuration for Admin Dashboard (Web)
// TODO: Run 'flutterfire configure' to generate proper web config
// Or manually add your Firebase web config here

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA6xBexGGzJfeoMgE2ELAX8FviHEHePDSc',
    appId:
        '1:123848762137:web:69e2eee300748b70fa5b88', // TODO: Add web app ID from Firebase Console
    messagingSenderId: '123848762137',
    projectId: 'mr-games-74165',
    authDomain: 'mr-games-74165.firebaseapp.com',
    storageBucket: 'mr-games-74165.firebasestorage.app',
  );

  static FirebaseOptions get currentPlatform => web;
}
