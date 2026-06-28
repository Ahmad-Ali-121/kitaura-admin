import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/admin_confirm_dialog.dart';
import '../controller/pro_templates_controller.dart';
import '../model/pro_templates_config.dart';

class ProTemplatesEditorScreen extends ConsumerStatefulWidget {
  const ProTemplatesEditorScreen({super.key});

  @override
  ConsumerState<ProTemplatesEditorScreen> createState() =>
      _ProTemplatesEditorScreenState();
}

class _ProTemplatesEditorScreenState
    extends ConsumerState<ProTemplatesEditorScreen> {
  final _addCtrl = TextEditingController();
  String? _addError;

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  void _handleAdd() {
    final id = _addCtrl.text.trim();
    final err = ref.read(proTemplatesProvider.notifier).addTemplate(id);
    if (err != null) {
      setState(() => _addError = err);
    } else {
      _addCtrl.clear();
      setState(() => _addError = null);
    }
  }

  Future<void> _confirmSave(int added, int removed) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminConfirmDialog(
        title: 'Save Pro template list',
        description:
        'Adding $added, removing $removed. After save, free users can '
            'still preview these templates in the editor, but exports will '
            'be blocked until they upgrade.',
        auditAction: 'adminUpdateConfig',
        confirmLabel: 'Save changes',
        onConfirm: (_) async {
          await ref.read(proTemplatesProvider.notifier).save();
        },
      ),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pro templates saved.'),
          backgroundColor: AppColors.darkRaspberry,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(proTemplatesProvider);
    final ctrl = ref.read(proTemplatesProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            isDirty: state.isDirty,
            added: state.addedCount,
            removed: state.removedCount,
            loading: state.loading,
            saving: state.saving,
            onRefresh: ctrl.load,
            onDiscard: ctrl.discard,
            onSave: () =>
                _confirmSave(state.addedCount, state.removedCount),
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
            _ChipsList(
              edited: state.edited!,
              originalSet: state.original?.proTemplates.toSet() ??
                  const <String>{},
              onRemove: ctrl.removeTemplate,
              disabled: state.saving,
            ),
            const SizedBox(height: 16),
            _AddCard(
              controller: _addCtrl,
              error: _addError,
              disabled: state.saving,
              onAdd: _handleAdd,
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── HEADER ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isDirty;
  final int added;
  final int removed;
  final bool loading;
  final bool saving;
  final VoidCallback onRefresh;
  final VoidCallback onDiscard;
  final VoidCallback onSave;

  const _Header({
    required this.isDirty,
    required this.added,
    required this.removed,
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
                'Pro Templates',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.prussianBlue,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Templates flagged here require Pro to export.',
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
              '+$added · −$removed unsaved',
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

// ─── CHIPS LIST ──────────────────────────────────────────────────────────

class _ChipsList extends StatelessWidget {
  final ProTemplatesConfig edited;
  final Set<String> originalSet;
  final ValueChanged<String> onRemove;
  final bool disabled;

  const _ChipsList({
    required this.edited,
    required this.originalSet,
    required this.onRemove,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    if (edited.proTemplates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.almondSilk),
        ),
        child: const Center(
          child: Text(
            'No Pro templates yet. Add IDs below.',
            style: TextStyle(color: AppColors.slateGrey, fontSize: 13),
          ),
        ),
      );
    }

    // Group by category
    final groups = <String, List<String>>{
      'CV': [],
      'Cover Letter': [],
      'Proposal': [],
    };
    for (final id in edited.proTemplates) {
      groups[ProTemplatesConfig.categoryOf(id)]!.add(id);
    }
    for (final list in groups.values) {
      list.sort();
    }

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
          for (final entry in groups.entries) ...[
            if (entry.value.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  '${entry.key.toUpperCase()} · ${entry.value.length}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.slateGrey,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value.map((id) {
                  final isNew = !originalSet.contains(id);
                  return _TemplateChip(
                    id: id,
                    isNew: isNew,
                    disabled: disabled,
                    onRemove: () => onRemove(id),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ],
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final String id;
  final bool isNew;
  final bool disabled;
  final VoidCallback onRemove;

  const _TemplateChip({
    required this.id,
    required this.isNew,
    required this.disabled,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
    isNew ? AppColors.magentaBloom : AppColors.almondSilk;
    final bg = isNew ? AppColors.petalFrost : AppColors.lavenderBlush;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: isNew ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            id,
            style: const TextStyle(
              fontFamily: 'OpenSans',
              fontSize: 12,
              color: AppColors.prussianBlue,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: disabled ? null : onRemove,
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.close,
                size: 14,
                color: AppColors.slateGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ADD CARD ─────────────────────────────────────────────────────────────

class _AddCard extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final bool disabled;
  final VoidCallback onAdd;

  const _AddCard({
    required this.controller,
    required this.error,
    required this.disabled,
    required this.onAdd,
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
            'Add template ID',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.prussianBlue,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Use the same ID string the main app uses. Prefix with '
                'cl_ for cover letters or prop_ for proposals.',
            style: TextStyle(fontSize: 12, color: AppColors.slateGrey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !disabled,
                  onSubmitted: (_) => onAdd(),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'e.g. modern_gradient',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: disabled ? null : onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.dangerRed,
              ),
            ),
          ],
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