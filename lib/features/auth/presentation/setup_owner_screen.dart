import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/errors/failure_messages.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/widgets/form_page.dart';
import 'package:tindascan/core/widgets/message_banner.dart';
import 'package:tindascan/core/widgets/password_field.dart';
import 'package:tindascan/core/widgets/primary_button.dart';
import 'package:tindascan/features/auth/application/auth_controllers.dart';
import 'package:tindascan/features/auth/domain/auth_validators.dart';
import 'package:tindascan/features/auth/presentation/auth_field_messages.dart';

/// One-time first-run flow that registers the store owner.
class SetupOwnerScreen extends ConsumerStatefulWidget {
  const SetupOwnerScreen({super.key});

  @override
  ConsumerState<SetupOwnerScreen> createState() => _SetupOwnerScreenState();
}

class _SetupOwnerScreenState extends ConsumerState<SetupOwnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeName = TextEditingController();
  final _ownerName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    for (final c in [_storeName, _ownerName, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(setupControllerProvider.notifier)
        .completeSetup(
          storeName: _storeName.text,
          ownerName: _ownerName.text,
          email: _email.text,
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(setupControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.setupTitle)),
      body: FormPage(
        children: [
          Text(l10n.setupSubtitle, style: theme.textTheme.bodyLarge),
          const SizedBox(height: Gaps.lg),
          if (state case AsyncError(:final error))
            MessageBanner(text: error.toUserMessage(l10n)),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _storeName,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  maxLength: AppConstants.maxStoreNameLength,
                  decoration: InputDecoration(
                    labelText: l10n.storeNameLabel,
                    prefixIcon: const Icon(Icons.storefront),
                  ),
                  validator: (v) => AuthValidators.name(
                    v,
                    maxLength: AppConstants.maxStoreNameLength,
                  ).toText(l10n, maxLength: AppConstants.maxStoreNameLength),
                ),
                const FieldGap(),
                TextFormField(
                  controller: _ownerName,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  maxLength: AppConstants.maxNameLength,
                  autofillHints: const [AutofillHints.name],
                  decoration: InputDecoration(
                    labelText: l10n.nameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) => AuthValidators.name(v).toText(l10n),
                ),
                const FieldGap(),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: l10n.emailLabel,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) => AuthValidators.email(v).toText(l10n),
                ),
                const FieldGap(),
                PasswordField(
                  controller: _password,
                  label: l10n.passwordLabel,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) => AuthValidators.newPassword(v).toText(l10n),
                ),
                const FieldGap(),
                PasswordField(
                  controller: _confirm,
                  label: l10n.confirmPasswordLabel,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => _submit(),
                  validator: (v) => AuthValidators.confirmPassword(
                    v,
                    _password.text,
                  ).toText(l10n),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gaps.lg),
          PrimaryButton(
            label: l10n.setupButton,
            isLoading: state.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
