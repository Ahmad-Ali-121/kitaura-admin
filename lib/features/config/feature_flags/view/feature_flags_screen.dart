import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/admin_confirm_dialog.dart';
import '../controller/feature_flags_controller.dart';
import '../model/feature_flags_config.dart';

class FeatureFlagsScreen extends ConsumerWidget {
  const FeatureFlagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(featureFlagsProvider);
    final ctrl = ref.read(featureFlagsProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            isDirty: state.isDirty,
            changeCount: state.changeCount,
            loading: state.loading,
            saving: state.saving,
            onRefresh: ctrl.load,
            onDiscard: ctrl.discard,
            onSave: () => _confirmSave(context, ref, state.changeCount),
          ),
          const SizedBox(height: 20),
          if (state.error != null) ...[
            _ErrorBlock(error: state.error!),
            const SizedBox(height: 14),
          ],
          if (state.loading && state.edited == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.darkRaspberry,
                ),
              ),
            )
          else if (state.edited != null)
            _FlagsList(
              edited: state.edited!,
              original: state.original!,
              onToggle: ctrl.toggle,
              disabled: state.saving,
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _confirmSave(
      BuildContext context,
      WidgetRef ref,
      int changeCount,
      ) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminConfirmDialog(
        title: 'Save feature flags',
        description:
        '$changeCount flag${changeCount == 1 ? '' : 's'} changed. '
            'Main app checks these on load; users will see the new state '
            'the next time they refresh.',
        auditAction: 'adminUpdateConfig',
        confirmLabel: 'Save changes',
        onConfirm: (_) async {
          await ref.read(featureFlagsProvider.notifier).save();
        },
      ),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feature flags saved.'),
          backgroundColor: AppColors.darkRaspberry,
        ),
      );
    }
  }
}

class _Header extends StatelessWidget {
  final bool isDirty;
  final int changeCount;
  final bool loading;
  final bool saving;
  final VoidCallback onRefresh;
  final VoidCallback onDiscard;
  final VoidCallback onSave;

  const _Header({
    required this.isDirty,
    required this.changeCount,
    required this.loading,
    required this.saving,
    required this.onRefresh,
    required this.onDiscard,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Feature Flags',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.prussianBlue,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Kill-switches for main-app features. No redeploy needed.',
                style: TextStyle(fontSize: 13, color: AppColors.slateGrey),
              ),
            ],
          ),
        ),
        if (isDirty)
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.petalFrost,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$changeCount unsaved',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.darkRaspberry,
                letterSpacing: 0.5,
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: (loading || saving) ? null : onRefresh,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Reload'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: (!isDirty || saving) ? null : onDiscard,
          icon: const Icon(Icons.undo, size: 16),
          label: const Text('Discard'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: (!isDirty || saving) ? null : onSave,
          icon: saving
              ? const SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.white,
            ),
          )
              : const Icon(Icons.save_outlined, size: 16),
          label: Text(saving ? 'Saving…' : 'Save changes'),
        ),
      ],
    );
  }
}

class _FlagsList extends StatelessWidget {
  final FeatureFlagsConfig edited;
  final FeatureFlagsConfig original;
  final void Function(String key, bool value) onToggle;
  final bool disabled;

  const _FlagsList({
    required this.edited,
    required this.original,
    required this.onToggle,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    // Show known flags first (in definition order), then any extras
    final knownKeys =
    FeatureFlagsConfig.knownFlags.map((f) => f.key).toSet();
    final orderedKeys = <String>[
      ...FeatureFlagsConfig.knownFlags.map((f) => f.key),
      ...edited.flags.keys.where((k) => !knownKeys.contains(k)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Column(
        children: [
          for (var i = 0; i < orderedKeys.length; i++) ...[
            if (i > 0)
              const Divider(
                color: AppColors.almondSilk,
                height: 0,
                thickness: 0.4,
              ),
            _FlagRow(
              flagKey: orderedKeys[i],
              value: edited.flags[orderedKeys[i]] ?? true,
              changed: edited.flags[orderedKeys[i]] !=
                  original.flags[orderedKeys[i]],
              disabled: disabled,
              onChanged: (v) => onToggle(orderedKeys[i], v),
            ),
          ],
        ],
      ),
    );
  }
}

class _FlagRow extends StatelessWidget {
  final String flagKey;
  final bool value;
  final bool changed;
  final bool disabled;
  final ValueChanged<bool> onChanged;

  const _FlagRow({
    required this.flagKey,
    required this.value,
    required this.changed,
    required this.disabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final def = FeatureFlagsConfig.knownFlags
        .where((f) => f.key == flagKey)
        .firstOrNull;

    final label = def?.label ?? flagKey;
    final description =
        def?.description ?? '(Unknown flag — main app uses default behavior)';

    return Container(
      color: changed
          ? AppColors.petalFrost.withValues(alpha: 0.4)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.prussianBlue,
                      ),
                    ),
                    if (changed) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.magentaBloom,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                SelectableText(
                  flagKey,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.slateGrey,
                    fontFamily: 'OpenSans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slateGrey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: disabled ? null : onChanged,
            activeThumbColor: AppColors.darkRaspberry,
          ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String error;
  const _ErrorBlock({required this.error});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppColors.dangerRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.dangerRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.prussianBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}