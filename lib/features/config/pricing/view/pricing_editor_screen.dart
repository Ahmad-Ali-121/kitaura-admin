import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/admin_confirm_dialog.dart';
import '../controller/pricing_controller.dart';
import '../model/pricing_config.dart';

class PricingEditorScreen extends ConsumerWidget {
  const PricingEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pricingProvider);
    final ctrl = ref.read(pricingProvider.notifier);

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
          else if (state.edited == null || state.edited!.models.isEmpty)
            const _Empty()
          else
            _ModelCards(
              edited: state.edited!,
              original: state.original!,
              onChange: ctrl.updateRate,
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
        title: 'Save pricing',
        description:
        '$changeCount field${changeCount == 1 ? '' : 's'} changed. '
            'New rates apply to AI calls made after the save completes. '
            'In-flight calls already use the old rates.',
        auditAction: 'adminUpdateConfig',
        confirmLabel: 'Save changes',
        onConfirm: (_) async {
          await ref.read(pricingProvider.notifier).save();
        },
      ),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pricing saved.'),
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
                'Model Pricing',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.prussianBlue,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Per-token rates used to compute AI call costs.',
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

class _ModelCards extends StatelessWidget {
  final PricingConfig edited;
  final PricingConfig original;
  final void Function(String model, String field, double value) onChange;
  final bool disabled;

  const _ModelCards({
    required this.edited,
    required this.original,
    required this.onChange,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    final models = edited.models.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in models) ...[
          _ModelCard(
            modelKey: m,
            editedRates: edited.models[m]!,
            originalRates: original.models[m] ?? const {},
            onChange: (field, value) => onChange(m, field, value),
            disabled: disabled,
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _ModelCard extends StatelessWidget {
  final String modelKey;
  final Map<String, double> editedRates;
  final Map<String, double> originalRates;
  final void Function(String field, double value) onChange;
  final bool disabled;

  const _ModelCard({
    required this.modelKey,
    required this.editedRates,
    required this.originalRates,
    required this.onChange,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    final isSonnet = modelKey.contains('sonnet');
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
                  color: isSonnet
                      ? AppColors.darkRaspberry
                      : AppColors.dustyMauve,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'MODEL',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SelectableText(
                  modelKey,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.prussianBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 700 ? 3 : 1;
              const gap = 14.0;
              final w = (c.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: PricingConfig.rateFields.map((f) {
                  return SizedBox(
                    width: w,
                    child: _DoubleField(
                      key: ValueKey('${modelKey}_${f}_${originalRates[f]}'),
                      label: PricingConfig.rateLabels[f]!,
                      hint: PricingConfig.rateHints[f]!,
                      initial: editedRates[f] ?? 0.0,
                      original: originalRates[f] ?? 0.0,
                      disabled: disabled,
                      onChanged: (v) => onChange(f, v),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── DOUBLE FIELD ────────────────────────────────────────────────────────

class _DoubleField extends StatefulWidget {
  final String label;
  final String hint;
  final double initial;
  final double original;
  final bool disabled;
  final ValueChanged<double> onChanged;

  const _DoubleField({
    super.key,
    required this.label,
    required this.hint,
    required this.initial,
    required this.original,
    required this.onChanged,
    this.disabled = false,
  });

  @override
  State<_DoubleField> createState() => _DoubleFieldState();
}

class _DoubleFieldState extends State<_DoubleField> {
  late final TextEditingController _ctrl;
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
    _ctrl = TextEditingController(text: _formatValue(_value));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _formatValue(double v) {
    // Strip trailing .0 if integer
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toString();
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
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
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
            hintText: widget.hint,
            hintStyle: const TextStyle(
              fontSize: 11,
              color: AppColors.slateGrey,
            ),
          ),
          onChanged: (text) {
            final parsed = double.tryParse(text);
            if (parsed != null && parsed >= 0) {
              setState(() => _value = parsed);
              widget.onChanged(parsed);
            }
          },
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: const Center(
        child: Text(
          'No models configured in config/pricing.',
          style: TextStyle(color: AppColors.slateGrey, fontSize: 13),
        ),
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