import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/admin_confirm_dialog.dart';
import '../controller/plan_limits_controller.dart';
import '../model/plan_limits_config.dart';

class PlanLimitsEditorScreen extends ConsumerWidget {
  const PlanLimitsEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(planLimitsProvider);
    final ctrl = ref.read(planLimitsProvider.notifier);

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
          else if (state.edited != null) ...[
            _PlanCards(
              edited: state.edited!,
              original: state.original!,
              onChange: ctrl.updateField,
              disabled: state.saving,
            ),
            const SizedBox(height: 16),
            _GlobalCard(
              edited: state.edited!,
              original: state.original!,
              onTrialDaysChange: ctrl.updateTrialDays,
              onPriceChange: ctrl.updateProMonthlyPrice,
              disabled: state.saving,
            ),
          ],
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
        title: 'Save plan limits',
        description:
        '$changeCount field${changeCount == 1 ? '' : 's'} changed. '
            'Saving will overwrite config/limits and apply to all users '
            'on their next AI/export call.',
        auditAction: 'adminUpdateConfig',
        confirmLabel: 'Save changes',
        onConfirm: (_) async {
          await ref.read(planLimitsProvider.notifier).save();
        },
      ),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan limits saved.'),
          backgroundColor: AppColors.darkRaspberry,
        ),
      );
    }
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────

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
                'Plan Limits',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.prussianBlue,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Live caps for guest / free / trial / pro plans. -1 = unlimited.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.slateGrey,
                ),
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
          icon: loading
              ? const SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.slateGrey,
            ),
          )
              : const Icon(Icons.refresh, size: 16),
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

// ─── PLAN CARDS ───────────────────────────────────────────────────────────

class _PlanCards extends StatelessWidget {
  final PlanLimitsConfig edited;
  final PlanLimitsConfig original;
  final void Function(String plan, String field, int value) onChange;
  final bool disabled;

  const _PlanCards({
    required this.edited,
    required this.original,
    required this.onChange,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 1280 ? 4 : c.maxWidth > 700 ? 2 : 1;
        const gap = 14.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: PlanLimitsConfig.planNames.map((plan) {
            return SizedBox(
              width: w,
              child: _PlanCard(
                plan: plan,
                edited: edited.plans[plan]!,
                original: original.plans[plan]!,
                onChange: (field, value) => onChange(plan, field, value),
                disabled: disabled,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String plan;
  final Map<String, int> edited;
  final Map<String, int> original;
  final void Function(String field, int value) onChange;
  final bool disabled;

  const _PlanCard({
    required this.plan,
    required this.edited,
    required this.original,
    required this.onChange,
    required this.disabled,
  });

  Color get _planColor {
    if (plan == 'pro') return AppColors.darkRaspberry;
    if (plan == 'trial') return AppColors.magentaBloom;
    if (plan == 'guest') return AppColors.dustyMauve;
    return AppColors.slateGrey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _planColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  plan.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final field in PlanLimitsConfig.fieldKeys) ...[
            _IntField(
              key: ValueKey('${plan}_${field}_${original[field]}'),
              label: PlanLimitsConfig.fieldLabels[field]!,
              initial: edited[field]!,
              original: original[field]!,
              disabled: disabled,
              onChanged: (v) => onChange(field, v),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ─── GLOBAL CARD ──────────────────────────────────────────────────────────

class _GlobalCard extends StatelessWidget {
  final PlanLimitsConfig edited;
  final PlanLimitsConfig original;
  final ValueChanged<int> onTrialDaysChange;
  final ValueChanged<num> onPriceChange;
  final bool disabled;

  const _GlobalCard({
    required this.edited,
    required this.original,
    required this.onTrialDaysChange,
    required this.onPriceChange,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Global',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.prussianBlue,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 240,
                child: _IntField(
                  key: ValueKey('trialDays_${original.trialDays}'),
                  label: 'Trial duration (days)',
                  initial: edited.trialDays,
                  original: original.trialDays,
                  minValue: 1,
                  disabled: disabled,
                  onChanged: onTrialDaysChange,
                ),
              ),
              SizedBox(
                width: 240,
                child: _IntField(
                  key: ValueKey(
                    'proPrice_${original.proMonthlyPrice}',
                  ),
                  label: 'Pro monthly price (\$)',
                  initial: edited.proMonthlyPrice.toInt(),
                  original: original.proMonthlyPrice.toInt(),
                  minValue: 0,
                  disabled: disabled,
                  onChanged: (v) => onPriceChange(v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── INT FIELD ────────────────────────────────────────────────────────────

class _IntField extends StatefulWidget {
  final String label;
  final int initial;
  final int original;
  final int minValue;
  final bool disabled;
  final ValueChanged<int> onChanged;

  const _IntField({
    super.key,
    required this.label,
    required this.initial,
    required this.original,
    required this.onChanged,
    this.minValue = -1,
    this.disabled = false,
  });

  @override
  State<_IntField> createState() => _IntFieldState();
}

class _IntFieldState extends State<_IntField> {
  late final TextEditingController _ctrl;
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
    _ctrl = TextEditingController(text: _value.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isChanged = _value != widget.original;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: AppColors.slateGrey,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (isChanged)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.magentaBloom,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _ctrl,
          enabled: !widget.disabled,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
          ],
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isChanged
                    ? AppColors.magentaBloom
                    : AppColors.almondSilk,
                width: isChanged ? 1.5 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isChanged
                    ? AppColors.magentaBloom
                    : AppColors.almondSilk,
                width: isChanged ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: AppColors.darkRaspberry,
                width: 1.5,
              ),
            ),
            hintText: widget.minValue == -1 ? '-1 = unlimited' : null,
            hintStyle: const TextStyle(
              fontSize: 11,
              color: AppColors.slateGrey,
            ),
          ),
          onChanged: (text) {
            final parsed = int.tryParse(text);
            if (parsed != null && parsed >= widget.minValue) {
              setState(() => _value = parsed);
              widget.onChanged(parsed);
            }
          },
        ),
      ],
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