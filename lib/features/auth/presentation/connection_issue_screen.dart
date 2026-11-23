import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/errors/error_mapper.dart';
import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/core/errors/failure_messages.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/widgets/form_page.dart';
import 'package:tindascan/core/widgets/message_banner.dart';
import 'package:tindascan/core/widgets/primary_button.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/auth/domain/session.dart';

/// Shown when the app cannot tell whether first-run setup is needed, e.g.
/// offline on first launch or the security rules are not deployed yet.
class ConnectionIssueScreen extends ConsumerWidget {
  const ConnectionIssueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(sessionProvider);
    final error = switch (session.value) {
      SessionSetupCheckFailed(:final error) => error,
      _ => null,
    };
    final isPermission = error != null && mapError(error) is PermissionDenied;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.connectionIssueTitle)),
      body: FormPage(
        children: [
          const Icon(Icons.cloud_off_outlined, size: AppSizes.iconLarge * 2),
          const FieldGap(),
          Text(
            l10n.connectionIssueMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: Gaps.lg),
          if (error != null) MessageBanner(text: error.toUserMessage(l10n)),
          if (isPermission)
            MessageBanner(
              text: l10n.connectionIssuePermissionHint,
              isError: false,
            ),
          PrimaryButton(
            label: l10n.retry,
            icon: Icons.refresh,
            isLoading: session.isLoading,
            onPressed: () => ref.invalidate(sessionProvider),
          ),
        ],
      ),
    );
  }
}
