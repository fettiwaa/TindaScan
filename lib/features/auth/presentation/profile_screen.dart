import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/errors/failure_messages.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/widgets/confirm_dialog.dart';
import 'package:tindascan/core/widgets/form_page.dart';
import 'package:tindascan/core/widgets/message_banner.dart';
import 'package:tindascan/core/widgets/primary_button.dart';
import 'package:tindascan/core/widgets/state_views.dart';
import 'package:tindascan/features/auth/application/auth_controllers.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/auth/domain/auth_validators.dart';
import 'package:tindascan/features/auth/presentation/auth_field_messages.dart';

/// The signed-in user's own profile (both roles) with sign-out.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: ref.read(currentUserProvider)?.name ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(profileControllerProvider.notifier).updateName(_name.text);
    if (!ref.read(profileControllerProvider).hasError) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
    }
  }

  Future<void> _signOut() async {
    final l10n = context.l10n;
    final controller = ref.read(profileControllerProvider.notifier);
    final unsynced = await controller.hasUnsyncedSales();
    if (!mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      title: unsynced ? l10n.signOutUnsyncedTitle : l10n.signOutConfirm,
      message: unsynced ? l10n.signOutUnsyncedMessage : null,
      confirmLabel: unsynced ? l10n.signOutAnyway : l10n.signOut,
      destructive: unsynced,
    );
    if (confirmed) await controller.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final state = ref.watch(profileControllerProvider);
    if (user == null) return const Scaffold(body: LoadingView());

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: FormPage(
        children: [
          if (state case AsyncError(:final error))
            MessageBanner(text: error.toUserMessage(l10n)),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text(l10n.emailLabel),
            subtitle: Text(user.email),
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text(l10n.profileRole),
            subtitle: Text(user.role.label(l10n)),
          ),
          const FieldGap(),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              maxLength: AppConstants.maxNameLength,
              decoration: InputDecoration(labelText: l10n.nameLabel),
              validator: (v) => AuthValidators.name(v).toText(l10n),
            ),
          ),
          const FieldGap(),
          PrimaryButton(
            label: l10n.save,
            isLoading: state.isLoading,
            onPressed: _save,
          ),
          const SizedBox(height: Gaps.xl),
          OutlinedButton.icon(
            onPressed: state.isLoading ? null : _signOut,
            icon: const Icon(Icons.logout),
            label: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}
