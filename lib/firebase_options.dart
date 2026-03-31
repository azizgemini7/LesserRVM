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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'it not supported by FlutLab yet, but you can add it manually',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'it not supported by FlutLab yet, but you can add it manually',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'it not supported by FlutLab yet, but you can add it manually',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
      apiKey: 'AIzaSyAgeYsF2diBs9WWECcMBiwLP50P2BBtBCc',
      iosBundleId: 'com.example.helloWorld',
      appId: '1:42656840839:ios:ee7e706ee1adefcd604c22',
      storageBucket: 'lessernaqaa.appspot.com',
      messagingSenderId: '42656840839',
      iosClientId: 'undefined',
      projectId: 'lessernaqaa');

  static const FirebaseOptions android = FirebaseOptions(
      apiKey: 'AIzaSyBZj_puw7srPuLrn-yQeJoAr4_f2VoKHVs',
      appId: '1:42656840839:android:77f73994a3fe5f68604c22',
      messagingSenderId: '42656840839',
      projectId: 'lessernaqaa',
      storageBucket: 'lessernaqaa.appspot.com');

  static const FirebaseOptions web = FirebaseOptions(
      apiKey: 'AIzaSyAy5KCLHwwIaqcDytOAARYz0EIizcSod4Y',
      authDomain: 'lessernaqaa.firebaseapp.com',
      projectId: 'lessernaqaa',
      storageBucket: 'lessernaqaa.appspot.com',
      messagingSenderId: '42656840839',
      appId: '1:42656840839:web:e5213885af4c6846604c22',
      measurementId: 'G-T44WZCQFTK');
}
