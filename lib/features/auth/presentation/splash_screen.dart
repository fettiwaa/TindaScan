import 'package:flutter/material.dart';

import 'package:tindascan/core/widgets/state_views.dart';

/// Shown while the session is being resolved.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: LoadingView());
}
