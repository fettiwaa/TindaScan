import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tindascan/core/errors/failure_messages.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/router/app_routes.dart';
import 'package:tindascan/core/widgets/confirm_dialog.dart';
import 'package:tindascan/core/widgets/state_views.dart';
import 'package:tindascan/features/auth/application/staff_controllers.dart';
import 'package:tindascan/shared/models/app_user.dart';

/// Owner-only list of staff accounts with activate/deactivate.
class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final staff = ref.watch(staffListProvider);

    ref.listen(staffControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toUserMessage(l10n))));
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.staffTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.staffNew),
        icon: const Icon(Icons.person_add_alt),
        label: Text(l10n.staffAdd),
      ),
      body: AsyncValueView<List<AppUser>>(
        value: staff,
        onRetry: () => ref.invalidate(staffListProvider),
        isEmpty: (list) => list.isEmpty,
        emptyMessage: l10n.staffEmpty,
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) => _StaffTile(user: list[index]),
        ),
      ),
    );
  }
}

class _StaffTile extends ConsumerWidget {
  const _StaffTile({required this.user});

  final AppUser user;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    if (user.active) {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.staffDeactivateTitle(user.name),
        message: l10n.staffDeactivateMessage,
        confirmLabel: l10n.staffDeactivate,
        destructive: true,
      );
      if (!confirmed) return;
    }
    await ref
        .read(staffControllerProvider.notifier)
        .setActive(uid: user.uid, active: !user.active);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final busy = ref.watch(
      staffControllerProvider.select((state) => state.isLoading),
    );
    return ListTile(
      leading: Icon(user.active ? Icons.person : Icons.person_off),
      title: Text(user.name),
      subtitle: Text(
        '${user.email}\n${user.active ? l10n.staffActive : l10n.staffInactive}',
      ),
      isThreeLine: true,
      trailing: TextButton(
        onPressed: busy ? null : () => _toggle(context, ref),
        child: Text(user.active ? l10n.staffDeactivate : l10n.staffActivate),
      ),
    );
  }
}
