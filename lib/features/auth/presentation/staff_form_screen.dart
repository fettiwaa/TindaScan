import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/errors/failure_messages.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/widgets/form_page.dart';
import 'package:tindascan/core/widgets/message_banner.dart';
import 'package:tindascan/core/widgets/password_field.dart';
import 'package:tindascan/core/widgets/primary_button.dart';
import 'package:tindascan/features/auth/application/staff_controllers.dart';
import 'package:tindascan/features/auth/domain/auth_validators.dart';
import 'package:tindascan/features/auth/presentation/auth_field_messages.dart';

/// Owner creates a staff login. The owner stays signed in (secondary app).
class StaffFormScreen extends ConsumerStatefulWidget {
  const StaffFormScreen({super.key});

  @override
  ConsumerState<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends ConsumerState<StaffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final created = await ref
        .read(staffControllerProvider.notifier)
        .createStaff(
          name: _name.text,
          email: _email.text,
          password: _password.text,
        );
    if (!created || !mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.staffCreated)));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(staffControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.staffNewTitle)),
      body: FormPage(
        children: [
          if (state case AsyncError(:final error))
            MessageBanner(text: error.toUserMessage(l10n)),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: AppConstants.maxNameLength,
                  decoration: InputDecoration(labelText: l10n.nameLabel),
                  validator: (v) => AuthValidators.name(v).toText(l10n),
                ),
                const FieldGap(),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: l10n.emailLabel),
                  validator: (v) => AuthValidators.email(v).toText(l10n),
                ),
                const FieldGap(),
                PasswordField(
                  controller: _password,
                  label: l10n.passwordLabel,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => _submit(),
                  validator: (v) => AuthValidators.newPassword(v).toText(l10n),
                ),
                const SizedBox(height: Gaps.sm),
                Text(
                  l10n.staffPasswordHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: Gaps.lg),
          PrimaryButton(
            label: l10n.staffAdd,
            isLoading: state.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
