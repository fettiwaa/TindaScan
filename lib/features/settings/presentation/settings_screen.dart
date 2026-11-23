import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/errors/failure_messages.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/router/app_routes.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/widgets/app_card.dart';
import 'package:tindascan/core/widgets/feedback_ui.dart';
import 'package:tindascan/core/widgets/form_controls.dart';
import 'package:tindascan/core/widgets/message_banner.dart';
import 'package:tindascan/core/widgets/primary_button.dart';
import 'package:tindascan/core/widgets/state_views.dart';
import 'package:tindascan/features/auth/domain/auth_validators.dart';
import 'package:tindascan/features/auth/presentation/auth_field_messages.dart';
import 'package:tindascan/features/products/domain/product_validators.dart';
import 'package:tindascan/features/products/presentation/product_labels.dart';
import 'package:tindascan/features/settings/application/app_preferences.dart';
import 'package:tindascan/features/settings/application/locale_provider.dart';
import 'package:tindascan/features/settings/application/settings_controller.dart';
import 'package:tindascan/features/settings/application/settings_providers.dart';
import 'package:tindascan/shared/models/store_settings.dart';

/// Owner settings: appearance, feedback, language, store, sample data.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(storeSettingsProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(l10n.settingsTitle)),
          const SliverToBoxAdapter(child: _DevicePreferences()),
          SliverToBoxAdapter(
            child: SectionHeader(title: l10n.settingsStoreSection),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.md),
            sliver: SliverToBoxAdapter(
              child: AsyncValueView<StoreSettings>(
                value: settings,
                loading: const SizedBox(height: 200, child: LoadingView()),
                onRetry: () => ref.invalidate(storeSettingsProvider),
                data: (s) => _StoreForm(key: ValueKey(s), initial: s),
              ),
            ),
          ),
          if (kDebugMode) const SliverToBoxAdapter(child: _DebugTools()),
          const SliverToBoxAdapter(child: SizedBox(height: Gaps.xl)),
        ],
      ),
    );
  }
}

/// Theme, feedback and language: stored on this phone only.
class _DevicePreferences extends ConsumerWidget {
  const _DevicePreferences();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs =
        ref.watch(appPreferencesProvider).value ?? const AppPreferences();
    final notifier = ref.read(appPreferencesProvider.notifier);
    final locale = ref.watch(localeProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.settingsAppearance),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.md),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<ThemeMode>(
                  key: const Key('theme-mode'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Symbols.brightness_auto_rounded),
                      label: Text(l10n.settingsThemeSystem),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Symbols.light_mode_rounded),
                      label: Text(l10n.settingsThemeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Symbols.dark_mode_rounded),
                      label: Text(l10n.settingsThemeDark),
                    ),
                  ],
                  selected: {prefs.themeMode},
                  onSelectionChanged: (s) => notifier.setThemeMode(s.first),
                ),
                const SizedBox(height: Gaps.md),
                DropdownButtonFormField<String>(
                  initialValue: locale?.languageCode ?? '',
                  decoration: InputDecoration(
                    labelText: l10n.settingsLanguage,
                    prefixIcon: const Icon(Symbols.translate_rounded),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(l10n.settingsLanguageSystem),
                    ),
                    const DropdownMenuItem(value: 'en', child: Text('English')),
                    const DropdownMenuItem(
                      value: 'fil',
                      child: Text('Filipino'),
                    ),
                  ],
                  onChanged: (code) => ref
                      .read(localeProvider.notifier)
                      .setLocale(
                        code == null || code.isEmpty ? null : Locale(code),
                      ),
                ),
              ],
            ),
          ),
        ),
        SectionHeader(title: l10n.settingsFeedbackSection),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.md),
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  key: const Key('haptics-switch'),
                  secondary: const Icon(Symbols.vibration_rounded),
                  title: Text(l10n.settingsHaptics),
                  subtitle: Text(l10n.settingsHapticsHint),
                  value: prefs.haptics,
                  onChanged: (v) => notifier.setHaptics(enabled: v),
                ),
                const Divider(indent: 72),
                SwitchListTile(
                  secondary: const Icon(Symbols.volume_up_rounded),
                  title: Text(l10n.settingsScanSound),
                  value: prefs.scanSound,
                  onChanged: (v) => notifier.setScanSound(enabled: v),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StoreForm extends ConsumerStatefulWidget {
  const _StoreForm({required this.initial, super.key});

  final StoreSettings initial;

  @override
  ConsumerState<_StoreForm> createState() => _StoreFormState();
}

class _StoreFormState extends ConsumerState<_StoreForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial.storeName);
  late final _threshold = TextEditingController(
    text: '${widget.initial.defaultLowStockThreshold}',
  );

  @override
  void dispose() {
    _name.dispose();
    _threshold.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final ok = await ref
        .read(settingsControllerProvider.notifier)
        .save(
          StoreSettings(
            storeName: _name.text.trim(),
            defaultLowStockThreshold: int.parse(_threshold.text.trim()),
          ),
        );
    if (ok && mounted) {
      showAppSnackBar(context, l10n.settingsSaved, type: SnackType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(settingsControllerProvider);
    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state case AsyncError(:final error))
              MessageBanner(text: error.toUserMessage(l10n)),
            AppTextField(
              controller: _name,
              label: l10n.storeNameLabel,
              icon: Symbols.storefront_rounded,
              maxLength: AppConstants.maxStoreNameLength,
              textCapitalization: TextCapitalization.words,
              validator: (v) => AuthValidators.name(
                v,
                maxLength: AppConstants.maxStoreNameLength,
              ).toText(l10n, maxLength: AppConstants.maxStoreNameLength),
            ),
            const SizedBox(height: Gaps.md),
            AppTextField(
              controller: _threshold,
              label: l10n.settingsDefaultThreshold,
              icon: Symbols.notifications_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => ProductValidators.threshold(v).toText(l10n),
            ),
            const SizedBox(height: Gaps.md),
            PrimaryButton(
              label: l10n.save,
              isLoading: state.isLoading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// Debug builds only: sample data and the design gallery.
class _DebugTools extends ConsumerWidget {
  const _DebugTools();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final busy = ref.watch(settingsControllerProvider).isLoading;

    Future<void> seed() async {
      final added = await ref
          .read(settingsControllerProvider.notifier)
          .seed(initialStockNote: l10n.productInitialStockNote);
      if (added != null && context.mounted) {
        showAppSnackBar(
          context,
          l10n.settingsSeedDone(added),
          type: SnackType.success,
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.settingsSeedTitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.md),
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  key: const Key('seed-button'),
                  leading: const Icon(Symbols.playlist_add_rounded),
                  title: Text(l10n.settingsSeedButton),
                  subtitle: Text(l10n.settingsSeedExplain),
                  enabled: !busy,
                  onTap: seed,
                ),
                const Divider(indent: 72),
                ListTile(
                  leading: const Icon(Symbols.palette_rounded),
                  title: Text(l10n.settingsDesignGallery),
                  trailing: const Icon(Symbols.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.designGallery),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
