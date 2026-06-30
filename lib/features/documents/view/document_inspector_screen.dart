// lib/features/documents/view/document_inspector_screen.dart
//
// Step 23 — Document Inspector at /admin/documents/:type/:uid/:docId.
//
// Read-only viewer. Four blocks:
//   1. Metadata card (title, owner, template, status, dates, exports)
//      with "Open owner" + "View document" buttons.
//   2. Canvas preview card — collapsible, renders the actual canvas
//      using AdminCanvasRenderer. Toggled by the "View document" button.
//   3. Items list — each row tappable to reveal its full JSON.
//   4. Raw document JSON — full Firestore doc as pretty-printed text.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../controller/admin_document_inspector_controller.dart';
import 'admin_canvas_renderer.dart';

class DocumentInspectorScreen extends ConsumerStatefulWidget {
  final String type;
  final String uid;
  final String docId;
  const DocumentInspectorScreen({
    super.key,
    required this.type,
    required this.uid,
    required this.docId,
  });

  @override
  ConsumerState<DocumentInspectorScreen> createState() =>
      _DocumentInspectorScreenState();
}

class _DocumentInspectorScreenState
    extends ConsumerState<DocumentInspectorScreen> {
  final Set<int> _expandedItems = {};
  bool _rawDocExpanded = false;
  bool _canvasVisible = false;

  @override
  Widget build(BuildContext context) {
    final ref = DocRef(
      uid: widget.uid,
      type: widget.type,
      docId: widget.docId,
    );
    final async = this.ref.watch(adminDocumentInspectorProvider(ref));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BackBar(
            onRefresh: () =>
                this.ref.invalidate(adminDocumentInspectorProvider(ref)),
            loading: async.isLoading,
          ),
          const SizedBox(height: 12),
          async.when(
            loading: () => const _Loading(),
            error: (e, _) => _ErrorBlock(error: e.toString()),
            data: (doc) => _Body(
              doc: doc,
              expandedItems: _expandedItems,
              rawDocExpanded: _rawDocExpanded,
              canvasVisible: _canvasVisible,
              onToggleItem: (idx) => setState(() {
                if (!_expandedItems.add(idx)) _expandedItems.remove(idx);
              }),
              onToggleRawDoc: () =>
                  setState(() => _rawDocExpanded = !_rawDocExpanded),
              onToggleCanvas: () =>
                  setState(() => _canvasVisible = !_canvasVisible),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── BACK BAR ────────────────────────────────────────────────────────────

class _BackBar extends StatelessWidget {
  final VoidCallback onRefresh;
  final bool loading;
  const _BackBar({required this.onRefresh, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => context.go('/admin/documents'),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back to documents'),
        ),
        const Spacer(),
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

// ─── BODY ────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final AdminDocument doc;
  final Set<int> expandedItems;
  final bool rawDocExpanded;
  final bool canvasVisible;
  final ValueChanged<int> onToggleItem;
  final VoidCallback onToggleRawDoc;
  final VoidCallback onToggleCanvas;

  const _Body({
    required this.doc,
    required this.expandedItems,
    required this.rawDocExpanded,
    required this.canvasVisible,
    required this.onToggleItem,
    required this.onToggleRawDoc,
    required this.onToggleCanvas,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetadataCard(
          doc: doc,
          canvasVisible: canvasVisible,
          onToggleCanvas: onToggleCanvas,
        ),
        const SizedBox(height: 16),
        _DocSpecificCard(doc: doc),
        if (canvasVisible) ...[
          const SizedBox(height: 16),
          _CanvasPreviewCard(
            doc: doc,
            onClose: onToggleCanvas,
          ),
        ],
        const SizedBox(height: 16),
        _ItemsCard(
          doc: doc,
          expandedItems: expandedItems,
          onToggleItem: onToggleItem,
        ),
        const SizedBox(height: 16),
        _RawDocCard(
          doc: doc,
          expanded: rawDocExpanded,
          onToggle: onToggleRawDoc,
        ),
      ],
    );
  }
}

// ─── METADATA CARD ───────────────────────────────────────────────────────

class _MetadataCard extends ConsumerWidget {
  final AdminDocument doc;
  final bool canvasVisible;
  final VoidCallback onToggleCanvas;

  const _MetadataCard({
    required this.doc,
    required this.canvasVisible,
    required this.onToggleCanvas,
  });

  String _typeLabel() {
    switch (doc.type) {
      case 'cv':
        return 'CV';
      case 'coverLetter':
        return 'Cover Letter';
      case 'proposal':
        return 'Proposal';
      default:
        return doc.type;
    }
  }

  IconData _typeIcon() {
    switch (doc.type) {
      case 'cv':
        return Icons.description_outlined;
      case 'coverLetter':
        return Icons.mail_outline;
      case 'proposal':
        return Icons.assignment_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('MMM d, yyyy · HH:mm');
    final data = doc.data;
    final title = (data['title'] ?? '(untitled)').toString();
    final templateId = data['templateId'] as String?;
    final status = (data['status'] ?? 'draft').toString();
    final isArchived = data['isArchived'] == true;
    final exportCount = (data['exportCount'] is num)
        ? (data['exportCount'] as num).toInt()
        : 0;
    final selectedProfileName = data['selectedProfileName'] as String?;

    DateTime? parseDate(String? s) =>
        s == null ? null : DateTime.tryParse(s);
    final createdAt = parseDate(data['createdAt'] as String?);
    final updatedAt = parseDate(data['updatedAt'] as String?);
    final lastExportedAt = parseDate(data['lastExportedAt'] as String?);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_typeIcon(), size: 18, color: AppColors.darkRaspberry),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.prussianBlue,
                  ),
                ),
              ),
              _Chip(
                label: _typeLabel().toUpperCase(),
                bg: AppColors.petalFrost,
                fg: AppColors.darkRaspberry,
              ),
              const SizedBox(width: 6),
              _StatusChip(status: status),
              if (isArchived) ...[
                const SizedBox(width: 6),
                const _Chip(
                  label: 'ARCHIVED',
                  bg: AppColors.almondSilk,
                  fg: AppColors.prussianBlue,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            'docId: ${doc.docId}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.slateGrey,
              fontFamily: 'OpenSans',
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _MiniInfo(
                icon: Icons.person_outline,
                label: 'Owner',
                value: doc.ownerEmail ?? '(no email)',
              ),
              _MiniInfo(
                icon: Icons.fingerprint,
                label: 'Owner UID',
                value: doc.uid,
              ),
              _MiniInfo(
                icon: Icons.style_outlined,
                label: 'Template',
                value: templateId ?? '—',
              ),
              if (selectedProfileName != null)
                _MiniInfo(
                  icon: Icons.account_box_outlined,
                  label: 'Career Profile',
                  value: selectedProfileName,
                ),
              _MiniInfo(
                icon: Icons.download_outlined,
                label: 'Exports',
                value: '$exportCount',
              ),
              _MiniInfo(
                icon: Icons.add_circle_outline,
                label: 'Created',
                value: createdAt == null
                    ? '—'
                    : dateFmt.format(createdAt.toLocal()),
              ),
              _MiniInfo(
                icon: Icons.edit_outlined,
                label: 'Updated',
                value: updatedAt == null
                    ? '—'
                    : dateFmt.format(updatedAt.toLocal()),
              ),
              if (lastExportedAt != null)
                _MiniInfo(
                  icon: Icons.history,
                  label: 'Last exported',
                  value: dateFmt.format(lastExportedAt.toLocal()),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go('/admin/users/${doc.uid}'),
                icon: const Icon(Icons.person_outline, size: 16),
                label: const Text('Open owner'),
              ),
              ElevatedButton.icon(
                onPressed: onToggleCanvas,
                icon: Icon(
                  canvasVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                ),
                label: Text(
                  canvasVisible ? 'Hide document' : 'View document',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── DOC-TYPE SPECIFIC CARD ──────────────────────────────────────────────

class _DocSpecificCard extends StatelessWidget {
  final AdminDocument doc;
  const _DocSpecificCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data;

    final fields = <(String, String, IconData)>[];

    if (doc.type == 'coverLetter') {
      final company = data['targetCompany'] as String?;
      final role = data['targetRole'] as String?;
      final hm = data['hiringManagerName'] as String?;
      final hmTitle = data['hiringManagerTitle'] as String?;
      final linkedCv = data['linkedCvId'] as String?;
      if (company != null && company.isNotEmpty) {
        fields.add(('Target company', company, Icons.business_outlined));
      }
      if (role != null && role.isNotEmpty) {
        fields.add(('Target role', role, Icons.work_outline));
      }
      if (hm != null && hm.isNotEmpty) {
        fields.add((
        'Hiring manager',
        hmTitle != null && hmTitle.isNotEmpty ? '$hm — $hmTitle' : hm,
        Icons.person_outline,
        ));
      }
      if (linkedCv != null && linkedCv.isNotEmpty) {
        fields.add(('Linked CV', linkedCv, Icons.link));
      }
    } else if (doc.type == 'proposal') {
      final clientName = data['clientName'] as String?;
      final scope = data['projectScope'] as String?;
      final linkedClient = data['linkedClientId'] as String?;
      final linkedCv = data['linkedCvId'] as String?;
      if (clientName != null && clientName.isNotEmpty) {
        fields.add(('Client name', clientName, Icons.business_outlined));
      }
      if (scope != null && scope.isNotEmpty) {
        fields.add(('Project scope', scope, Icons.summarize_outlined));
      }
      if (linkedClient != null && linkedClient.isNotEmpty) {
        fields.add(('Linked client profile', linkedClient, Icons.link));
      }
      if (linkedCv != null && linkedCv.isNotEmpty) {
        fields.add(('Linked CV', linkedCv, Icons.link));
      }
    }

    if (fields.isEmpty) return const SizedBox.shrink();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            doc.type == 'coverLetter' ? 'Job details' : 'Project details',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.prussianBlue,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: fields
                .map((f) => _MiniInfo(
              icon: f.$3,
              label: f.$1,
              value: f.$2,
            ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── CANVAS PREVIEW CARD ─────────────────────────────────────────────────

class _CanvasPreviewCard extends StatelessWidget {
  final AdminDocument doc;
  final VoidCallback onClose;
  const _CanvasPreviewCard({
    required this.doc,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data;
    final canvasBg = data['canvasBackground'] as String?;
    final items = doc.items;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.visibility_outlined,
                size: 18,
                color: AppColors.darkRaspberry,
              ),
              const SizedBox(width: 8),
              const Text(
                'Document preview',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.prussianBlue,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lavenderBlush,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'READ-ONLY',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dustyMauve,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.slateGrey,
                tooltip: 'Hide preview',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Visual approximation — fonts and Quill formatting may differ '
                'from the live PDF export.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.slateGrey,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warmGrey,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.almondSilk),
            ),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppColors.prussianBlue.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AdminCanvasRenderer(
                items: items,
                canvasBackground: canvasBg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ITEMS CARD ──────────────────────────────────────────────────────────

class _ItemsCard extends StatelessWidget {
  final AdminDocument doc;
  final Set<int> expandedItems;
  final ValueChanged<int> onToggleItem;

  const _ItemsCard({
    required this.doc,
    required this.expandedItems,
    required this.onToggleItem,
  });

  Map<String, int> _typeCounts(List<Map<String, dynamic>> items) {
    final counts = <String, int>{};
    for (final it in items) {
      final t = (it['type'] ?? 'unknown').toString();
      counts[t] = (counts[t] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final items = doc.items;
    final counts = _typeCounts(items);
    final canvasBg = doc.data['canvasBackground'] as String?;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Canvas items',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.prussianBlue,
                ),
              ),
              const SizedBox(width: 10),
              _Chip(
                label: '${items.length} TOTAL',
                bg: AppColors.petalFrost,
                fg: AppColors.darkRaspberry,
              ),
              if (canvasBg != null) ...[
                const SizedBox(width: 6),
                _ColorSwatch(hex: canvasBg, label: 'BG'),
              ],
            ],
          ),
          if (counts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: counts.entries
                  .map((e) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.lavenderBlush,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: AppColors.almondSilk),
                ),
                child: Text(
                  '${e.key}: ${e.value}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slateGrey,
                    letterSpacing: 0.4,
                  ),
                ),
              ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'This document has no canvas items.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.slateGrey,
                ),
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  _ItemRow(
                    index: i,
                    item: items[i],
                    expanded: expandedItems.contains(i),
                    onToggle: () => onToggleItem(i),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item;
  final bool expanded;
  final VoidCallback onToggle;

  const _ItemRow({
    required this.index,
    required this.item,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final type = (item['type'] ?? 'unknown').toString();
    final sectionType = item['sectionType'] as String?;
    final title = item['title'] as String?;
    final x = item['x'] is num ? (item['x'] as num).toDouble() : 0.0;
    final y = item['y'] is num ? (item['y'] as num).toDouble() : 0.0;
    final w = item['w'] is num ? (item['w'] as num).toDouble() : 0.0;
    final h = item['h'] is num ? (item['h'] as num).toDouble() : 0.0;
    final color = item['color'] as String?;

    final summary = StringBuffer();
    summary.write(type);
    if (sectionType != null) summary.write(' · $sectionType');
    if (title != null && title.isNotEmpty) summary.write(' · $title');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: expanded ? AppColors.lavenderBlush : AppColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      'i$index',
                      style: const TextStyle(
                        fontFamily: 'OpenSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slateGrey,
                      ),
                    ),
                  ),
                  if (color != null) ...[
                    _ColorSwatch(hex: color),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      summary.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'OpenSans',
                        color: AppColors.prussianBlue,
                      ),
                    ),
                  ),
                  Text(
                    'x:${x.toStringAsFixed(0)} y:${y.toStringAsFixed(0)} '
                        '${w.toStringAsFixed(0)}×${h.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'OpenSans',
                      color: AppColors.slateGrey,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: AppColors.slateGrey,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            _JsonBlock(
              json: item,
              copyLabel: 'Copy item JSON',
            ),
        ],
      ),
    );
  }
}

// ─── RAW DOC CARD ────────────────────────────────────────────────────────

class _RawDocCard extends StatelessWidget {
  final AdminDocument doc;
  final bool expanded;
  final VoidCallback onToggle;

  const _RawDocCard({
    required this.doc,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(
                    Icons.data_object,
                    size: 18,
                    color: AppColors.darkRaspberry,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Raw document JSON',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.prussianBlue,
                      ),
                    ),
                  ),
                  Text(
                    expanded ? 'Hide' : 'Show',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slateGrey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.slateGrey,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: _JsonBlock(
                json: doc.data,
                copyLabel: 'Copy raw JSON',
              ),
            ),
        ],
      ),
    );
  }
}

// ─── JSON BLOCK ──────────────────────────────────────────────────────────

class _JsonBlock extends StatelessWidget {
  final Map<String, dynamic> json;
  final String copyLabel;
  const _JsonBlock({required this.json, required this.copyLabel});

  @override
  Widget build(BuildContext context) {
    final pretty = const JsonEncoder.withIndent('  ').convert(json);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.prussianBlue,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: pretty));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('JSON copied to clipboard'),
                      backgroundColor: AppColors.darkRaspberry,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.petalFrost,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                ),
                icon: const Icon(Icons.copy_outlined, size: 14),
                label: Text(
                  copyLabel,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 480),
            child: SingleChildScrollView(
              child: SelectableText(
                pretty,
                style: const TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 11,
                  height: 1.5,
                  color: AppColors.petalFrost,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SHARED ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final double padding;
  const _Card({required this.child, this.padding = 20});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: child,
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MiniInfo({
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.slateGrey),
              const SizedBox(width: 5),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: AppColors.slateGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          SelectableText(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.prussianBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Chip({required this.label, required this.bg, required this.fg});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.8,
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
    return _Chip(label: s.toUpperCase(), bg: bg, fg: fg);
  }
}

class _ColorSwatch extends StatelessWidget {
  final String hex;
  final String? label;
  const _ColorSwatch({required this.hex, this.label});

  Color? _parse() {
    var h = hex.replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final v = int.tryParse(h, radix: 16);
    if (v == null) return null;
    return Color(v);
  }

  @override
  Widget build(BuildContext context) {
    final c = _parse();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: c ?? AppColors.almondSilk,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: AppColors.almondSilk),
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(
            label!,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.slateGrey,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.darkRaspberry),
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