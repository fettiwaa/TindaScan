import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/config/env.dart';
import 'package:tindascan/core/constants/app_constants.dart';

/// Raw Firebase SDK singletons. Only the data layer may depend on these;
/// tests override the repository providers instead.
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

/// Lazily initializes the secondary app used for staff account creation.
Future<FirebaseAuth> secondaryAuthFactory() async {
  final existing = Firebase.apps.where(
    (app) => app.name == AppConstants.staffCreatorAppName,
  );
  if (existing.isNotEmpty) {
    return FirebaseAuth.instanceFor(app: existing.first);
  }
  final app = await Firebase.initializeApp(
    name: AppConstants.staffCreatorAppName,
    options: Firebase.app().options,
  );
  final auth = FirebaseAuth.instanceFor(app: app);
  if (Env.useEmulator) {
    await auth.useAuthEmulator(Env.emulatorHost, Env.authEmulatorPort);
  }
  return auth;
}
