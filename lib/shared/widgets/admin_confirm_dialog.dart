import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Generic confirmation dialog for admin mutations.
///
/// Use via `showDialog<bool>(...)` — it pops `true` on success, `false` on
/// cancel, and surfaces errors inline. `onConfirm` receives the parsed
/// days input (or `null` when `showDaysInput` is false).
class AdminConfirmDialog extends StatefulWidget {
  final String title;
  final String description;
  final String auditAction;
  final bool destructive;
  final bool showDaysInput;
  final int daysInitial;
  final String daysLabel;
  final String confirmLabel;
  final Future<void> Function(int? days) onConfirm;

  const AdminConfirmDialog({
    super.key,
    required this.title,
    required this.description,
    required this.auditAction,
    required this.onConfirm,
    this.destructive = false,
    this.showDaysInput = false,
    this.daysInitial = 30,
    this.daysLabel = 'Days',
    this.confirmLabel = 'Confirm',
  });

  @override
  State<AdminConfirmDialog> createState() => _AdminConfirmDialogState();
}

class _AdminConfirmDialogState extends State<AdminConfirmDialog> {
  late final TextEditingController _daysCtrl;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _daysCtrl =
        TextEditingController(text: widget.daysInitial.toString());
  }

  @override
  void dispose() {
    _daysCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    int? days;
    if (widget.showDaysInput) {
      days = int.tryParse(_daysCtrl.text.trim());
      if (days == null || days < 1) {
        setState(() => _error = 'Enter a valid number (1 or more).');
        return;
      }
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onConfirm(days);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirmColor =
    widget.destructive ? AppColors.dangerRed : AppColors.darkRaspberry;

    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      title: Text(
        widget.title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          color: AppColors.prussianBlue,
          fontSize: 17,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.prussianBlue,
                height: 1.4,
              ),
            ),
            if (widget.showDaysInput) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _daysCtrl,
                  enabled: !_loading,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: widget.daysLabel,
                    isDense: true,
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.dangerRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.dangerRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.dangerRed, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        _error!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.prussianBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.lavenderBlush,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.almondSilk),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history,
                      size: 14, color: AppColors.slateGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Logged as: ${widget.auditAction} by you',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.slateGrey,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.slateGrey),
          ),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
          ),
          child: _loading
              ? const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.white,
            ),
          )
              : Text(widget.confirmLabel),
        ),
      ],
    );
  }
}