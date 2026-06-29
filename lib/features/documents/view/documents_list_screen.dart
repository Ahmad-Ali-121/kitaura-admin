// lib/features/documents/view/documents_list_screen.dart
//
// Step 23 — Documents List at /admin/documents.
//
// Cross-user document browser. Type filter at top. Table of titles
// with owner, template, status, exports, last-updated. Click row →
// Document Inspector.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../controller/admin_documents_list_controller.dart';

class DocumentsListScreen extends ConsumerWidget {
  const DocumentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDocumentsListProvider);
    final ctrl = ref.read(adminDocumentsListProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(loading: state.loading, onRefresh: ctrl.refresh),
          const SizedBox(height: 16),
          _Filters(
            typeFilter: state.typeFilter,
            onType: ctrl.setType,
          ),
          const SizedBox(height: 16),
          if (state.error != null) ...[
            _ErrorBlock(error: state.error!),
            const SizedBox(height: 14),
          ],
          if (state.loading && state.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.darkRaspberry,
                ),
              ),
            )
          else if (state.items.isEmpty)
            const _Empty()
          else ...[
              _Table(
                rows: state.items,
                onRowTap: (doc) {
                  if (doc.uid == null) return;
                  context.go(
                    '/admin/documents/${doc.type}/${doc.uid}/${doc.docId}',
                  );
                },
              ),
              const SizedBox(height: 16),
              if (state.hasMore)
                Center(
                  child: OutlinedButton.icon(
                    onPressed: state.loadingMore ? null : ctrl.loadMore,
                    icon: state.loadingMore
                        ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.darkRaspberry,
                      ),
                    )
                        : const Icon(Icons.expand_more, size: 16),
                    label: Text(
                      state.loadingMore ? 'Loading…' : 'Load 25 more',
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
  final bool loading;
  final VoidCallback onRefresh;
  const _Header({required this.loading, required this.onRefresh});

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
                'Documents',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.prussianBlue,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Browse documents across all users · ordered by most recently updated',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.slateGrey,
                ),
              ),
            ],
          ),
        ),
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
    );
  }
}

// ─── FILTERS ──────────────────────────────────────────────────────────────

class _Filters extends StatelessWidget {
  final String typeFilter;
  final ValueChanged<String> onType;
  const _Filters({required this.typeFilter, required this.onType});

  static const _options = [
    ('cv', 'CVs', Icons.description_outlined),
    ('coverLetter', 'Cover Letters', Icons.mail_outline),
    ('proposal', 'Proposals', Icons.assignment_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _options.map((opt) {
          final active = typeFilter == opt.$1;
          return InkWell(
            onTap: () => onType(opt.$1),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.darkRaspberry
                    : AppColors.lavenderBlush,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? AppColors.darkRaspberry
                      : AppColors.almondSilk,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    opt.$3,
                    size: 14,
                    color: active
                        ? AppColors.white
                        : AppColors.slateGrey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    opt.$2,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? AppColors.white
                          : AppColors.prussianBlue,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── TABLE ───────────────────────────────────────────────────────────────

class _Table extends StatelessWidget {
  final List<AdminDocumentSummary> rows;
  final ValueChanged<AdminDocumentSummary> onRowTap;
  const _Table({required this.rows, required this.onRowTap});

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
          for (var i = 0; i < rows.length; i++) ...[
            const Divider(
              color: AppColors.almondSilk,
              height: 0,
              thickness: 0.3,
            ),
            _DataRow(row: rows[i], onTap: () => onRowTap(rows[i])),
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
        color: AppColors.lavenderBlush,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 4, child: _HCell('TITLE')),
          Expanded(flex: 4, child: _HCell('OWNER')),
          Expanded(flex: 3, child: _HCell('TEMPLATE')),
          SizedBox(width: 80, child: _HCell('STATUS')),
          SizedBox(
            width: 70,
            child: _HCell('EXPORTS', align: TextAlign.right),
          ),
          SizedBox(
            width: 130,
            child: _HCell('UPDATED', align: TextAlign.right),
          ),
          SizedBox(width: 24),
        ],
      ),
    );
  }
}

class _HCell extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _HCell(this.text, {this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.slateGrey,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final AdminDocumentSummary row;
  final VoidCallback onTap;
  const _DataRow({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, HH:mm');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.prussianBlue,
                    ),
                  ),
                  Text(
                    '${row.itemCount} items',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.slateGrey,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.ownerEmail ?? '(no email)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.prussianBlue,
                    ),
                  ),
                  Text(
                    row.uid ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.slateGrey,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                row.templateId ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'OpenSans',
                  color: AppColors.slateGrey,
                ),
              ),
            ),
            SizedBox(width: 80, child: _StatusChip(status: row.status)),
            SizedBox(
              width: 70,
              child: Text(
                '${row.exportCount}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: row.exportCount > 0
                      ? AppColors.darkRaspberry
                      : AppColors.slateGrey,
                ),
              ),
            ),
            SizedBox(
              width: 130,
              child: Text(
                row.updatedAt == null
                    ? '—'
                    : dateFmt.format(row.updatedAt!.toLocal()),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.slateGrey,
                ),
              ),
            ),
            const SizedBox(
              width: 24,
              child: Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.slateGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    late Color bg;
    late Color fg;
    if (s == 'complete') {
      bg = AppColors.darkRaspberry;
      fg = AppColors.white;
    } else {
      bg = AppColors.petalFrost;
      fg = AppColors.darkRaspberry;
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          s.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

// ─── STATES ──────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: const Center(
        child: Text(
          'No documents of this type yet.',
          style: TextStyle(color: AppColors.slateGrey, fontSize: 14),
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