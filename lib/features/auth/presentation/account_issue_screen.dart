import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/widgets/form_page.dart';
import 'package:tindascan/core/widgets/primary_button.dart';
import 'package:tindascan/features/auth/application/auth_controllers.dart';

/// Signed in to Auth but without a `users/{uid}` profile.
class AccountIssueScreen extends ConsumerWidget {
  const AccountIssueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(profileControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountIssueTitle)),
      body: FormPage(
        children: [
          const Icon(Icons.person_off_outlined, size: AppSizes.iconLarge * 2),
          const FieldGap(),
          Text(
            l10n.accountIssueMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: Gaps.lg),
          PrimaryButton(
            label: l10n.signOut,
            icon: Icons.logout,
            isLoading: state.isLoading,
            onPressed: () =>
                ref.read(profileControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}
