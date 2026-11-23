import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/errors/failure_messages.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/widgets/form_page.dart';
import 'package:tindascan/core/widgets/message_banner.dart';
import 'package:tindascan/core/widgets/password_field.dart';
import 'package:tindascan/core/widgets/primary_button.dart';
import 'package:tindascan/features/auth/application/auth_controllers.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/auth/domain/auth_validators.dart';
import 'package:tindascan/features/auth/domain/session.dart';
import 'package:tindascan/features/auth/presentation/auth_field_messages.dart';

/// E-mail/password sign-in. Navigation after success is handled by the
/// router reacting to the session, not by this screen.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _info = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(loginControllerProvider.notifier)
        .signIn(email: _email.text, password: _password.text);
  }

  Future<void> _forgotPassword() async {
    final l10n = context.l10n;
    if (AuthValidators.email(_email.text) != null) {
      setState(() => _info = l10n.enterEmailFirst);
      return;
    }
    final sent = await ref
        .read(loginControllerProvider.notifier)
        .sendPasswordReset(_email.text);
    if (mounted && sent) setState(() => _info = l10n.resetEmailSent);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(loginControllerProvider);
    final reason = ref.watch(signOutReasonProvider);

    return Scaffold(
      body: FormPage(
        children: [
          Icon(
            Icons.storefront,
            size: AppSizes.iconLarge * 2,
            color: theme.colorScheme.primary,
            semanticLabel: l10n.appTitle,
          ),
          const FieldGap(),
          Text(
            l10n.appTitle,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          Text(
            l10n.loginSubtitle,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Gaps.lg),
          if (reason == SignOutReason.deactivated)
            MessageBanner(text: l10n.deactivatedMessage),
          if (state case AsyncError(:final error))
            MessageBanner(text: error.toUserMessage(l10n)),
          if (_info != null) MessageBanner(text: _info!, isError: false),
          Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('login-email'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: l10n.emailLabel,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (v) => AuthValidators.email(v).toText(l10n),
                  ),
                  const FieldGap(),
                  PasswordField(
                    key: const Key('login-password'),
                    controller: _password,
                    label: l10n.passwordLabel,
                    onSubmitted: (_) => _submit(),
                    validator: (v) =>
                        AuthValidators.loginPassword(v).toText(l10n),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Gaps.lg),
          PrimaryButton(
            key: const Key('login-submit'),
            label: l10n.loginButton,
            isLoading: state.isLoading,
            onPressed: _submit,
          ),
          const FieldGap(),
          TextButton(
            onPressed: state.isLoading ? null : _forgotPassword,
            child: Text(l10n.forgotPassword),
          ),
        ],
      ),
    );
  }
}
