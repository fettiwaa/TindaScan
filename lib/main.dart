import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/app.dart';
import 'package:tindascan/bootstrap.dart';
import 'package:tindascan/core/config/env.dart';
import 'package:tindascan/core/errors/global_error_handler.dart';

/// Entry point.
///
/// Architecture (layered client-service over a BaaS):
///   presentation (screens/widgets)
///     -> application (Riverpod notifiers / providers)
///       -> repository interfaces (lib/shared/repositories)
///         -> data implementations (Firebase Auth / Cloud Firestore)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();

  if (!Env.isConfigured) {
    runApp(const FirebaseNotConfiguredApp());
    return;
  }

  await initFirebase();
  runApp(
    ProviderScope(
      // Disable Riverpod's automatic retry: errors are shown with an explicit
      // "Retry" button instead, which avoids silent repeated Firestore reads.
      retry: (_, _) => null,
      child: const TindaScanApp(),
    ),
  );
}
