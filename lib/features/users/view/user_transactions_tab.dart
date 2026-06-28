// lib/features/users/view/user_transactions_tab.dart
//
// User Transactions tab (Step 18). Renders inside User Detail.
//
// Read-only view of the user's most recent transactions:
//   - 4 stat pills (total / exports / docs created / plan changes)
//   - Chronological table with category-colored type chips
//
// No mutations. No Cloud Function calls. Just a straight Firestore read
// gated by the admin custom claim in Firestore security rules.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../controller/user_transactions_controller.dart';

class UserTransactionsTab extends ConsumerWidget {
  final String uid;
  const UserTransactionsTab({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userTransactionsProvider(uid));

    return async.when(
      loading: () => const _Loading(),
      error: (e, _) => _ErrorBlock(error: e.toString()),
      data: (txs) {
        if (txs.isEmpty) return const _EmptyState();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatsRow(txs: txs),
            const SizedBox(height: 14),
            _TransactionTable(txs: txs),
          ],
        );
      },
    );
  }
}

// ─── STATS PILLS ─────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final List<AdminTransaction> txs;
  const _StatsRow({required this.txs});

  @override
  Widget build(BuildContext context) {
    int exports = 0;
    int docsCreated = 0;
    int planEvents = 0;
    for (final t in txs) {
      switch (t.category) {
        case TransactionCategory.export:
          exports++;
          break;
        case TransactionCategory.docCreated:
          docsCreated++;
          break;
        case TransactionCategory.plan:
          planEvents++;
          break;
        case TransactionCategory.docDeleted:
        case TransactionCategory.other:
          break;
      }
    }

    final pills = <Widget>[
      _StatPill(
        icon: Icons.receipt_long_outlined,
        label: 'Recent',
        value: '${txs.length}',
        sublabel: txs.length >= 100 ? 'capped at 100' : null,
      ),
      _StatPill(
        icon: Icons.download_outlined,
        label: 'Exports',
        value: '$exports',
      ),
      _StatPill(
        icon: Icons.add_circle_outline,
        label: 'Docs created',
        value: '$docsCreated',
      ),
      _StatPill(
        icon: Icons.workspace_premium_outlined,
        label: 'Plan changes',
        value: '$planEvents',
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 700 ? 4 : 2;
        const gap = 10.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: pills.map((p) => SizedBox(width: w, child: p)).toList(),
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sublabel;
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.lavenderBlush,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.slateGrey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.slateGrey,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.prussianBlue,
            ),
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 2),
            Text(
              sublabel!,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.slateGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── TABLE ───────────────────────────────────────────────────────────────

class _TransactionTable extends StatelessWidget {
  final List<AdminTransaction> txs;
  const _TransactionTable({required this.txs});

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
          const _HeaderRow(),
          for (int i = 0; i < txs.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.almondSilk,
              ),
            _DataRow(tx: txs[i]),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.petalFrost,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(width: 150, child: _HCell('TYPE')),
          Expanded(child: _HCell('DETAILS')),
          SizedBox(width: 80, child: _HCell('TOOL')),
          SizedBox(width: 160, child: _HCell('WHEN', alignEnd: true)),
        ],
      ),
    );
  }
}

class _HCell extends StatelessWidget {
  final String text;
  final bool alignEnd;
  const _HCell(this.text, {this.alignEnd = false});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.slateGrey,
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final AdminTransaction tx;
  const _DataRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy · HH:mm');
    final when =
    tx.createdAt == null ? '—' : dateFmt.format(tx.createdAt!.toLocal());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: _TypeChip(tx: tx)),
          Expanded(child: _DetailsCell(tx: tx)),
          SizedBox(
            width: 80,
            child: Text(
              tx.tool ?? '—',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.slateGrey,
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: Text(
              when,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.slateGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TYPE CHIP (category-colored) ────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final AdminTransaction tx;
  const _TypeChip({required this.tx});

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    switch (tx.category) {
      case TransactionCategory.export:
        bg = AppColors.petalFrost;
        fg = AppColors.darkRaspberry;
        break;
      case TransactionCategory.docCreated:
        bg = AppColors.lavenderBlush;
        fg = AppColors.dustyMauve;
        break;
      case TransactionCategory.docDeleted:
        bg = AppColors.almondSilk.withValues(alpha: 0.35);
        fg = AppColors.prussianBlue;
        break;
      case TransactionCategory.plan:
        bg = AppColors.magentaBloom;
        fg = AppColors.white;
        break;
      case TransactionCategory.other:
        bg = AppColors.almondSilk.withValues(alpha: 0.25);
        fg = AppColors.slateGrey;
        break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _humanizeType(tx.type),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: fg,
          ),
        ),
      ),
    );
  }

  String _humanizeType(String type) {
    switch (type) {
      case 'export':
        return 'EXPORT';
      case 'cvCreated':
        return 'CV CREATED';
      case 'coverLetterCreated':
        return 'CL CREATED';
      case 'proposalCreated':
        return 'PROPOSAL CREATED';
      case 'cvDeleted':
        return 'CV DELETED';
      case 'coverLetterDeleted':
        return 'CL DELETED';
      case 'proposalDeleted':
        return 'PROPOSAL DELETED';
      case 'trialActivated':
        return 'TRIAL ACTIVATED';
      case 'planUpgrade':
        return 'PLAN UPGRADE';
      case 'planDowngrade':
        return 'PLAN DOWNGRADE';
      case 'planRenewal':
        return 'PLAN RENEWAL';
      default:
        return type.toUpperCase();
    }
  }
}

// ─── DETAILS CELL ────────────────────────────────────────────────────────

class _DetailsCell extends StatelessWidget {
  final AdminTransaction tx;
  const _DetailsCell({required this.tx});

  @override
  Widget build(BuildContext context) {
    final title = tx.documentTitle;
    final metadataLine = _formatMetadata(tx.metadata);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title.isNotEmpty)
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: AppColors.prussianBlue,
            ),
          )
        else if (tx.documentId != null)
          Text(
            'Doc: ${tx.documentId}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.slateGrey,
            ),
          )
        else
          const Text(
            '—',
            style: TextStyle(fontSize: 12, color: AppColors.slateGrey),
          ),
        if (metadataLine != null) ...[
          const SizedBox(height: 2),
          Text(
            metadataLine,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.slateGrey,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  String? _formatMetadata(Map<String, dynamic> meta) {
    if (meta.isEmpty) return null;
    // Pull the most useful keys first if present; fall back to a flat join.
    final preferred = <String>['templateId', 'plan', 'cycleDays', 'days', 'reason'];
    final parts = <String>[];
    for (final k in preferred) {
      if (meta.containsKey(k) && meta[k] != null) {
        parts.add('$k: ${meta[k]}');
      }
    }
    for (final entry in meta.entries) {
      if (preferred.contains(entry.key)) continue;
      if (entry.value == null) continue;
      final v = entry.value;
      if (v is Map || v is List) continue; // skip nested clutter
      parts.add('${entry.key}: $v');
      if (parts.length >= 4) break;
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

// ─── STATES ──────────────────────────────────────────────────────────────

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.darkRaspberry),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.lavenderBlush,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 28,
              color: AppColors.slateGrey,
            ),
            SizedBox(height: 8),
            Text(
              'No transactions yet.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.slateGrey,
              ),
            ),
          ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.dangerRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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