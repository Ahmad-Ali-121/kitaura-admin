import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/services/admin_functions_service.dart';
import '../model/user_documents.dart';

final userDocumentsProvider = FutureProvider.autoDispose
    .family<UserDocumentsBundle, String>((ref, uid) async {
  final res = await AdminFunctionsService.listUserDocuments(targetUid: uid);
  return UserDocumentsBundle.fromMap(res);
});

class UserDocumentsTab extends ConsumerWidget {
  final String uid;
  const UserDocumentsTab({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userDocumentsProvider(uid));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.darkRaspberry,
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: _ErrorBlock(error: e.toString()),
      ),
      data: (bundle) {
        if (bundle.totalCount == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'This user has not created any documents yet.',
                style: TextStyle(color: AppColors.slateGrey, fontSize: 13),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CountStrip(bundle: bundle),
            const SizedBox(height: 12),
            if (bundle.cvs.isNotEmpty) ...[
              _DocSection(
                title: 'CVs',
                icon: Icons.description_outlined,
                docs: bundle.cvs,
                kind: _DocKind.cv,
              ),
              const SizedBox(height: 12),
            ],
            if (bundle.coverLetters.isNotEmpty) ...[
              _DocSection(
                title: 'Cover Letters',
                icon: Icons.mail_outline,
                docs: bundle.coverLetters,
                kind: _DocKind.coverLetter,
              ),
              const SizedBox(height: 12),
            ],
            if (bundle.proposals.isNotEmpty) ...[
              _DocSection(
                title: 'Proposals',
                icon: Icons.assignment_outlined,
                docs: bundle.proposals,
                kind: _DocKind.proposal,
              ),
              const SizedBox(height: 12),
            ],
            Center(
              child: TextButton.icon(
                onPressed: () => ref.invalidate(userDocumentsProvider(uid)),
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Refresh'),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _DocKind { cv, coverLetter, proposal }

class _CountStrip extends StatelessWidget {
  final UserDocumentsBundle bundle;
  const _CountStrip({required this.bundle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Pill(
            label: 'CVs',
            value: bundle.cvs.length.toString(),
            color: AppColors.darkRaspberry,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Pill(
            label: 'Cover Letters',
            value: bundle.coverLetters.length.toString(),
            color: AppColors.dustyMauve,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Pill(
            label: 'Proposals',
            value: bundle.proposals.length.toString(),
            color: AppColors.magentaBloom,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Pill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.slateGrey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<UserDocumentSummary> docs;
  final _DocKind kind;

  const _DocSection({
    required this.title,
    required this.icon,
    required this.docs,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.almondSilk),
      ),
      child: Column(
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.lavenderBlush,
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: AppColors.darkRaspberry),
                const SizedBox(width: 6),
                Text(
                  '${title.toUpperCase()} · ${docs.length}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slateGrey,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < docs.length; i++) ...[
            if (i > 0)
              const Divider(
                color: AppColors.almondSilk,
                height: 0,
                thickness: 0.3,
              ),
            _DocRow(doc: docs[i], kind: kind),
          ],
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  final UserDocumentSummary doc;
  final _DocKind kind;
  const _DocRow({required this.doc, required this.kind});

  String _subtitle() {
    final parts = <String>[];
    if (doc.templateId != null) parts.add('Template: ${doc.templateId}');
    if (kind == _DocKind.coverLetter && doc.targetCompany != null) {
      parts.add('To: ${doc.targetCompany}');
    }
    if (kind == _DocKind.proposal && doc.clientName != null) {
      parts.add('Client: ${doc.clientName}');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        doc.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.prussianBlue,
                        ),
                      ),
                    ),
                    if (doc.isArchived) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.slateGrey
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'ARCHIVED',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slateGrey,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_subtitle().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _subtitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.slateGrey,
                    ),
                  ),
                ],
                const SizedBox(height: 1),
                SelectableText(
                  doc.id,
                  style: const TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 9,
                    color: AppColors.almondSilk,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: _StatusChip(status: doc.status),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${doc.exportCount} export${doc.exportCount == 1 ? '' : 's'}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.slateGrey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              doc.updatedAt == null
                  ? '—'
                  : dateFmt.format(doc.updatedAt!.toLocal()),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.slateGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isComplete = status == 'complete';
    final color = isComplete
        ? AppColors.dustyMauve
        : AppColors.slateGrey;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.6,
          ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: AppColors.dangerRed.withValues(alpha: 0.3)),
      ),
      child: SelectableText(
        error,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.prussianBlue,
        ),
      ),
    );
  }
}