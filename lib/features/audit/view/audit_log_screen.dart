import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../controller/admin_audit_controller.dart';
import '../model/admin_activity.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminAuditProvider);
    final ctrl = ref.read(adminAuditProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(count: state.items.length, loading: state.loading),
          const SizedBox(height: 20),
          _Filters(
            actionFilter: state.actionFilter,
            timeRange: state.timeRange,
            loading: state.loading,
            onActionChanged: ctrl.setActionFilter,
            onTimeRangeChanged: ctrl.setTimeRange,
            onRefresh: () => ctrl.load(reset: true),
          ),
          const SizedBox(height: 14),
          if (state.error != null) ...[
            _ErrorBlock(error: state.error!),
            const SizedBox(height: 14),
          ],
          _LogTable(items: state.items, loading: state.loading),
          const SizedBox(height: 14),
          if (state.hasMore)
            Center(
              child: OutlinedButton.icon(
                onPressed: state.loading ? null : ctrl.load,
                icon: const Icon(Icons.expand_more, size: 16),
                label: state.loading
                    ? const Text('Loading…')
                    : const Text('Load more'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  final bool loading;
  const _Header({required this.count, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audit Log',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.prussianBlue,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Every admin mutation, oldest at the bottom',
                style: TextStyle(fontSize: 13, color: AppColors.slateGrey),
              ),
            ],
          ),
        ),
        if (!loading)
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.petalFrost,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count loaded',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.darkRaspberry,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  final String actionFilter;
  final String timeRange;
  final bool loading;
  final ValueChanged<String> onActionChanged;
  final ValueChanged<String> onTimeRangeChanged;
  final VoidCallback onRefresh;

  const _Filters({
    required this.actionFilter,
    required this.timeRange,
    required this.loading,
    required this.onActionChanged,
    required this.onTimeRangeChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<String>(
                  value: actionFilter,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      size: 18, color: AppColors.slateGrey),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.prussianBlue,
                    fontFamily: 'OpenSans',
                  ),
                  items: adminActionTypes
                      .map(
                        (a) => DropdownMenuItem(
                      value: a,
                      child: Text(a == 'all' ? 'All actions' : a),
                    ),
                  )
                      .toList(),
                  onChanged: (v) =>
                  v == null ? null : onActionChanged(v),
                ),
                _RangeChips(
                  value: timeRange,
                  onChanged: onTimeRangeChanged,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: loading ? null : onRefresh,
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
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _RangeChips extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _RangeChips({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String v) {
      final selected = value == v;
      return GestureDetector(
        onTap: () => onChanged(v),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.darkRaspberry : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.darkRaspberry
                  : AppColors.almondSilk,
            ),
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip('24h', '24h'),
        const SizedBox(width: 6),
        chip('7d', '7d'),
        const SizedBox(width: 6),
        chip('30d', '30d'),
        const SizedBox(width: 6),
        chip('All', 'all'),
      ],
    );
  }
}

// ─── TABLE ────────────────────────────────────────────────────────────────

class _LogTable extends StatelessWidget {
  final List<AdminActivity> items;
  final bool loading;
  const _LogTable({required this.items, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Column(
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.petalFrost,
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('TIME', style: _h)),
                Expanded(flex: 3, child: Text('ADMIN', style: _h)),
                Expanded(flex: 3, child: Text('ACTION', style: _h)),
                Expanded(flex: 3, child: Text('TARGET', style: _h)),
                Expanded(flex: 5, child: Text('CHANGE', style: _h)),
                SizedBox(width: 24),
              ],
            ),
          ),
          if (loading && items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.darkRaspberry,
                ),
              ),
            )
          else if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No audit entries match these filters.',
                  style:
                  TextStyle(color: AppColors.slateGrey, fontSize: 13),
                ),
              ),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                const Divider(
                  color: AppColors.almondSilk,
                  height: 0,
                  thickness: 0.4,
                ),
              _LogRow(entry: items[i]),
            ],
        ],
      ),
    );
  }
}

class _LogRow extends StatefulWidget {
  final AdminActivity entry;
  const _LogRow({required this.entry});

  @override
  State<_LogRow> createState() => _LogRowState();
}

class _LogRowState extends State<_LogRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('MMM d, HH:mm:ss');
    final entry = widget.entry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          hoverColor: AppColors.lavenderBlush,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.createdAt == null
                        ? '—'
                        : timeFmt.format(entry.createdAt!.toLocal()),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.prussianBlue,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.adminEmail ?? entry.adminUid,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.prussianBlue,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: _ActionPill(action: entry.action),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.target.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.prussianBlue,
                        ),
                      ),
                      Text(
                        entry.target.type,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.slateGrey,
                          fontFamily: 'Poppins',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    entry.diffSummary,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slateGrey,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.slateGrey,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            color: AppColors.lavenderBlush,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                _DetailLine('Entry ID', entry.id),
                _DetailLine('Admin UID', entry.adminUid),
                if (entry.target.id != null)
                  _DetailLine('Target ID', entry.target.id!),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _JsonBlock('BEFORE', entry.before)),
                    const SizedBox(width: 10),
                    Expanded(child: _JsonBlock('AFTER', entry.after)),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String action;
  const _ActionPill({required this.action});
  @override
  Widget build(BuildContext context) {
    final isMutation = action.startsWith('admin') &&
        !action.startsWith('adminGet') &&
        !action.startsWith('adminList');
    final color =
    isMutation ? AppColors.dustyMauve : AppColors.slateGrey;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          action,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;
  const _DetailLine(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: AppColors.slateGrey,
                letterSpacing: 0.7,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.prussianBlue,
                fontFamily: 'OpenSans',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JsonBlock extends StatelessWidget {
  final String label;
  final Map<String, dynamic> data;
  const _JsonBlock(this.label, this.data);

  @override
  Widget build(BuildContext context) {
    final pretty = const JsonEncoder.withIndent('  ').convert(data);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              color: AppColors.slateGrey,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            pretty,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'OpenSans',
              color: AppColors.prussianBlue,
              height: 1.4,
            ),
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

const _h = TextStyle(
  fontFamily: 'Poppins',
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 1,
  color: AppColors.slateGrey,
);