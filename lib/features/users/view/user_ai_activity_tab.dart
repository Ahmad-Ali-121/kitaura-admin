import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/services/admin_functions_service.dart';
import '../../ai/model/ai_activity_summary.dart';

/// Auto-disposed family provider — refetches when user navigates back into
/// the screen with a different uid.
final userAiActivityProvider = FutureProvider.autoDispose
    .family<List<AiActivitySummary>, String>((ref, uid) async {
  final res = await AdminFunctionsService.listAiActivity(
    userId: uid,
    limit: 50,
  );
  final items = (res['items'] as List? ?? [])
      .map((e) => AiActivitySummary.fromMap(Map<String, dynamic>.from(e)))
      .toList();
  return items;
});

class UserAiActivityTab extends ConsumerWidget {
  final String uid;
  const UserAiActivityTab({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userAiActivityProvider(uid));

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
      data: (items) {
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'This user has no AI activity yet.',
                style: TextStyle(color: AppColors.slateGrey, fontSize: 13),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryStrip(items: items),
            const SizedBox(height: 12),
            _Table(items: items),
            const SizedBox(height: 14),
            Center(
              child: TextButton.icon(
                onPressed: () => ref.invalidate(userAiActivityProvider(uid)),
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

class _SummaryStrip extends StatelessWidget {
  final List<AiActivitySummary> items;
  const _SummaryStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items.length;
    final totalCost =
    items.fold<double>(0, (a, b) => a + b.totalCost);
    final failures =
        items.where((it) => it.status == 'error').length;
    final refusals =
        items.where((it) => it.status == 'refused').length;

    return Row(
      children: [
        Expanded(
          child: _Pill(
            label: 'Recent calls',
            value: total.toString(),
            color: AppColors.dustyMauve,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Pill(
            label: 'Spend',
            value: '\$${totalCost.toStringAsFixed(4)}',
            color: AppColors.darkRaspberry,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Pill(
            label: 'Failures',
            value: failures.toString(),
            color: AppColors.dangerRed,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Pill(
            label: 'Refusals',
            value: refusals.toString(),
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
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Table extends StatelessWidget {
  final List<AiActivitySummary> items;
  const _Table({required this.items});

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('MMM d, HH:mm');
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
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.lavenderBlush,
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: const Row(
              children: [
                _Th('TIME', flex: 3),
                _Th('TOOL · TYPE', flex: 3),
                _Th('STATUS', flex: 2),
                _Th('COST', flex: 2, align: TextAlign.right),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(
                color: AppColors.almondSilk,
                height: 0,
                thickness: 0.3,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      items[i].createdAt == null
                          ? '—'
                          : timeFmt
                          .format(items[i].createdAt!.toLocal()),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.prussianBlue,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].tool ?? '—',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.prussianBlue,
                          ),
                        ),
                        if (items[i].type != null)
                          Text(
                            items[i].type!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.slateGrey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _StatusChip(status: items[i].status),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '\$${items[i].totalCost.toStringAsFixed(4)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.prussianBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Th extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign align;
  const _Th(this.text, {this.flex = 1, this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.slateGrey,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String? status;
  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case 'success':
        return AppColors.dustyMauve;
      case 'error':
        return AppColors.dangerRed;
      case 'refused':
        return AppColors.magentaBloom;
      case 'cancelled':
        return AppColors.slateGrey;
      default:
        return AppColors.almondSilk;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _color, width: 1),
        ),
        child: Text(
          (status ?? '—').toUpperCase(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: _color,
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