import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:tindascan/core/config/env.dart';

/// Cache budget for offline persistence (~40 MB is plenty for a store's
/// catalog and recent sales while staying gentle on low-end phones).
const int _firestoreCacheBytes = 40 * 1024 * 1024;

/// Initializes Firebase, App Check, offline persistence and the emulators.
Future<void> initFirebase() async {
  await Firebase.initializeApp(options: Env.firebaseOptions);

  // App Check: Play Integrity in release, the debug provider in debug builds
  // (register the debug token printed in logcat in the Firebase console).
  // Skipped against the local emulators, which do not enforce App Check.
  if (!Env.useEmulator) await _activateAppCheck();

  // Offline persistence lets the catalog and cart keep working on flaky
  // connections. NOTE: transactions still need a connection (see checkout).
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: _firestoreCacheBytes,
  );

  if (Env.useEmulator) {
    await FirebaseAuth.instance.useAuthEmulator(
      Env.emulatorHost,
      Env.authEmulatorPort,
    );
    FirebaseFirestore.instance.useFirestoreEmulator(
      Env.emulatorHost,
      Env.firestoreEmulatorPort,
    );
  }
}

Future<void> _activateAppCheck() => FirebaseAppCheck.instance.activate(
  providerAndroid: kDebugMode
      ? const AndroidDebugProvider()
      : const AndroidPlayIntegrityProvider(),
  providerApple: kDebugMode
      ? const AppleDebugProvider()
      : const AppleDeviceCheckProvider(),
  providerWeb: Env.recaptchaSiteKey.isEmpty
      ? null
      : ReCaptchaV3Provider(Env.recaptchaSiteKey),
);
