import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/admin_confirm_dialog.dart';
import '../controller/announcement_controller.dart';
import '../model/announcement_config.dart';

class AnnouncementEditorScreen extends ConsumerStatefulWidget {
  const AnnouncementEditorScreen({super.key});

  @override
  ConsumerState<AnnouncementEditorScreen> createState() =>
      _AnnouncementEditorScreenState();
}

class _AnnouncementEditorScreenState
    extends ConsumerState<AnnouncementEditorScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _linkUrlCtrl = TextEditingController();
  final _linkLabelCtrl = TextEditingController();

  AnnouncementConfig? _lastSeenOriginal;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _linkUrlCtrl.dispose();
    _linkLabelCtrl.dispose();
    super.dispose();
  }

  void _syncControllersFromState(AnnouncementConfig edited) {
    // Only overwrite controller text if our cached "last seen" is null
    // (initial load) or original changed (after save reload).
    if (_lastSeenOriginal != null) return;
    _titleCtrl.text = edited.title;
    _bodyCtrl.text = edited.body;
    _linkUrlCtrl.text = edited.linkUrl ?? '';
    _linkLabelCtrl.text = edited.linkLabel ?? '';
  }

  void _setEdited(AnnouncementConfig newCfg) {
    ref.read(announcementProvider.notifier).update(newCfg);
  }

  Future<void> _confirmSave() async {
    final state = ref.read(announcementProvider);
    if (state.edited == null) return;
    final isTurningOn =
        state.edited!.active && state.original?.active != true;
    final isTurningOff =
        !state.edited!.active && state.original?.active == true;

    final desc = isTurningOn
        ? 'You are turning the banner ON. All KitAura users will see this '
        'announcement at the top of every page on their next load.'
        : isTurningOff
        ? 'You are turning the banner OFF. The banner will disappear '
        'for all users on their next page load.'
        : 'You are saving banner content while keeping its '
        'active state unchanged.';

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminConfirmDialog(
        title: 'Save announcement',
        description: desc,
        auditAction: 'adminUpdateAnnouncement',
        confirmLabel: 'Save changes',
        onConfirm: (_) async {
          await ref.read(announcementProvider.notifier).save();
        },
      ),
    );
    if (ok == true && mounted) {
      // Reset cached original so controllers re-sync on reload
      _lastSeenOriginal = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Announcement saved.'),
          backgroundColor: AppColors.darkRaspberry,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(announcementProvider);
    final ctrl = ref.read(announcementProvider.notifier);

    // Detect first load OR a fresh original arriving (after save reload)
    if (state.original != null && _lastSeenOriginal == null) {
      _syncControllersFromState(state.edited!);
      _lastSeenOriginal = state.original;
    } else if (state.original != null &&
        _lastSeenOriginal != null &&
        !state.original!.differsFrom(_lastSeenOriginal!) == false) {
      // No-op; just to silence analyzer warnings about reassignment
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            isDirty: state.isDirty,
            loading: state.loading,
            saving: state.saving,
            onRefresh: () {
              _lastSeenOriginal = null;
              ctrl.load();
            },
            onDiscard: () {
              _lastSeenOriginal = null;
              ctrl.discard();
              // After discard, original == edited, so resync controllers
              if (state.edited != null) {
                _titleCtrl.text = state.original!.title;
                _bodyCtrl.text = state.original!.body;
                _linkUrlCtrl.text = state.original!.linkUrl ?? '';
                _linkLabelCtrl.text = state.original!.linkLabel ?? '';
              }
            },
            onSave: _confirmSave,
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
            _PreviewCard(cfg: state.edited!),
            const SizedBox(height: 16),
            _FormCard(
              cfg: state.edited!,
              disabled: state.saving,
              titleCtrl: _titleCtrl,
              bodyCtrl: _bodyCtrl,
              linkUrlCtrl: _linkUrlCtrl,
              linkLabelCtrl: _linkLabelCtrl,
              onActiveChanged: (v) =>
                  _setEdited(state.edited!.copyWith(active: v)),
              onTitleChanged: (v) =>
                  _setEdited(state.edited!.copyWith(title: v)),
              onBodyChanged: (v) =>
                  _setEdited(state.edited!.copyWith(body: v)),
              onSeverityChanged: (v) =>
                  _setEdited(state.edited!.copyWith(severity: v)),
              onLinkUrlChanged: (v) => _setEdited(
                state.edited!.copyWith(
                  linkUrl: v.isEmpty ? null : v,
                  clearLinkUrl: v.isEmpty,
                ),
              ),
              onLinkLabelChanged: (v) => _setEdited(
                state.edited!.copyWith(
                  linkLabel: v.isEmpty ? null : v,
                  clearLinkLabel: v.isEmpty,
                ),
              ),
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
  final bool loading;
  final bool saving;
  final VoidCallback onRefresh;
  final VoidCallback onDiscard;
  final VoidCallback onSave;

  const _Header({
    required this.isDirty,
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
                'Announcement',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.prussianBlue,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'System banner shown to all KitAura users.',
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
            child: const Text(
              'unsaved',
              style: TextStyle(
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

// ─── PREVIEW ──────────────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final AnnouncementConfig cfg;
  const _PreviewCard({required this.cfg});

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
          const Row(
            children: [
              Icon(Icons.visibility_outlined,
                  size: 16, color: AppColors.slateGrey),
              SizedBox(width: 6),
              Text(
                'LIVE PREVIEW',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slateGrey,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!cfg.active)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lavenderBlush,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.almondSilk),
              ),
              child: const Row(
                children: [
                  Icon(Icons.visibility_off_outlined,
                      size: 16, color: AppColors.slateGrey),
                  SizedBox(width: 8),
                  Text(
                    'Banner is OFF — no user sees this right now.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.slateGrey,
                    ),
                  ),
                ],
              ),
            )
          else
            _PreviewBanner(cfg: cfg),
        ],
      ),
    );
  }
}

class _PreviewBanner extends StatelessWidget {
  final AnnouncementConfig cfg;
  const _PreviewBanner({required this.cfg});

  ({Color bg, Color fg, Color border, IconData icon}) get _styling {
    switch (cfg.severity) {
      case 'critical':
        return (
        bg: AppColors.darkRaspberry,
        fg: AppColors.white,
        border: AppColors.darkRaspberry,
        icon: Icons.error_outline,
        );
      case 'warn':
        return (
        bg: AppColors.dustyRose,
        fg: AppColors.prussianBlue,
        border: AppColors.magentaBloom,
        icon: Icons.warning_amber_outlined,
        );
      case 'info':
      default:
        return (
        bg: AppColors.petalFrost,
        fg: AppColors.prussianBlue,
        border: AppColors.dustyMauve,
        icon: Icons.campaign_outlined,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _styling;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: s.border, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(s.icon, color: s.fg, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cfg.title.isEmpty ? '(no title)' : cfg.title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: s.fg,
                  ),
                ),
                if (cfg.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    cfg.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: s.fg.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (cfg.linkUrl != null) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: s.fg.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                cfg.linkLabel ?? 'Learn more',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: s.fg,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── FORM ─────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final AnnouncementConfig cfg;
  final bool disabled;
  final TextEditingController titleCtrl;
  final TextEditingController bodyCtrl;
  final TextEditingController linkUrlCtrl;
  final TextEditingController linkLabelCtrl;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onBodyChanged;
  final ValueChanged<String> onSeverityChanged;
  final ValueChanged<String> onLinkUrlChanged;
  final ValueChanged<String> onLinkLabelChanged;

  const _FormCard({
    required this.cfg,
    required this.disabled,
    required this.titleCtrl,
    required this.bodyCtrl,
    required this.linkUrlCtrl,
    required this.linkLabelCtrl,
    required this.onActiveChanged,
    required this.onTitleChanged,
    required this.onBodyChanged,
    required this.onSeverityChanged,
    required this.onLinkUrlChanged,
    required this.onLinkLabelChanged,
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
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Banner active',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.prussianBlue,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'When ON, every user sees this banner.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.slateGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: cfg.active,
                onChanged: disabled ? null : onActiveChanged,
                activeThumbColor: AppColors.darkRaspberry,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _FieldLabel('Title'),
          const SizedBox(height: 4),
          TextField(
            controller: titleCtrl,
            enabled: !disabled,
            onChanged: onTitleChanged,
            maxLength: 200,
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'e.g. Scheduled maintenance Saturday 6pm UTC',
            ),
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Body'),
          const SizedBox(height: 4),
          TextField(
            controller: bodyCtrl,
            enabled: !disabled,
            onChanged: onBodyChanged,
            minLines: 3,
            maxLines: 6,
            maxLength: 2000,
            decoration: const InputDecoration(
              isDense: true,
              hintText:
              'Plain text. Markdown not rendered in main app yet.',
            ),
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Severity'),
          const SizedBox(height: 4),
          _SeverityChips(
            value: cfg.severity,
            disabled: disabled,
            onChanged: onSeverityChanged,
          ),
          const SizedBox(height: 18),
          const _FieldLabel('Optional CTA'),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: linkUrlCtrl,
                  enabled: !disabled,
                  onChanged: onLinkUrlChanged,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Link URL (https://…)',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: linkLabelCtrl,
                  enabled: !disabled,
                  onChanged: onLinkLabelChanged,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Button label',
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.slateGrey,
        letterSpacing: 1,
      ),
    );
  }
}

class _SeverityChips extends StatelessWidget {
  final String value;
  final bool disabled;
  final ValueChanged<String> onChanged;
  const _SeverityChips({
    required this.value,
    required this.disabled,
    required this.onChanged,
  });

  Widget _chip(String label, String v, Color color) {
    final selected = value == v;
    return GestureDetector(
      onTap: disabled ? null : () => onChanged(v),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppColors.almondSilk),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.slateGrey,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip('Info', 'info', AppColors.dustyMauve),
        const SizedBox(width: 8),
        _chip('Warning', 'warn', AppColors.magentaBloom),
        const SizedBox(width: 8),
        _chip('Critical', 'critical', AppColors.darkRaspberry),
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