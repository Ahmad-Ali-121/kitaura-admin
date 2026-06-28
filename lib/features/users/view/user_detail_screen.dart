import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/services/admin_functions_service.dart';
import '../../../shared/widgets/admin_confirm_dialog.dart';
import '../controller/admin_user_detail_controller.dart';
import '../model/admin_user_detail.dart';

class UserDetailScreen extends ConsumerWidget {
  final String uid;
  const UserDetailScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminUserDetailProvider(uid));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BackBar(
            onRefresh: () =>
                ref.invalidate(adminUserDetailProvider(uid)),
            loading: async.isLoading,
          ),
          const SizedBox(height: 12),
          async.when(
            loading: () => const _Loading(),
            error: (err, _) => _ErrorBlock(error: err.toString()),
            data: (user) => _Body(user: user, ref: ref),
          ),
        ],
      ),
    );
  }
}

class _BackBar extends StatelessWidget {
  final VoidCallback onRefresh;
  final bool loading;
  const _BackBar({required this.onRefresh, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => context.go('/admin/users'),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back to users'),
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

class _Body extends StatelessWidget {
  final AdminUserDetail user;
  final WidgetRef ref;
  const _Body({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileCard(user: user),
        const SizedBox(height: 16),
        _SubscriptionCard(user: user),
        const SizedBox(height: 16),
        _ActionsCard(user: user, ref: ref),
        const SizedBox(height: 16),
        _LifetimeCard(user: user),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── PROFILE CARD ─────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final AdminUserDetail user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy · HH:mm');
    final initial = (user.email ?? '?').substring(0, 1).toUpperCase();

    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.darkRaspberry,
            backgroundImage: user.photoUrl != null
                ? NetworkImage(user.photoUrl!)
                : null,
            child: user.photoUrl == null
                ? Text(
              initial,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: AppColors.white,
              ),
            )
                : null,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.displayName ?? user.email ?? '(no name)',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.prussianBlue,
                        ),
                      ),
                    ),
                    if (user.isAdminUser) ...[
                      const _Chip(
                        label: 'ADMIN',
                        bg: AppColors.magentaBloom,
                        fg: AppColors.white,
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (user.disabled)
                      const _Chip(
                        label: 'DISABLED',
                        bg: AppColors.dangerRed,
                        fg: AppColors.white,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                SelectableText(
                  user.email ?? '(no email)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.slateGrey,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  'UID: ${user.uid}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.slateGrey,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    _MiniInfo(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: user.phone ?? '—',
                    ),
                    _MiniInfo(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: user.location ?? '—',
                    ),
                    _MiniInfo(
                      icon: Icons.login_outlined,
                      label: 'Last sign-in',
                      value: user.authLastSignInAt == null
                          ? '—'
                          : dateFmt
                          .format(user.authLastSignInAt!.toLocal()),
                    ),
                    _MiniInfo(
                      icon: Icons.person_add_outlined,
                      label: 'Signed up',
                      value: user.authCreatedAt == null
                          ? '—'
                          : dateFmt
                          .format(user.authCreatedAt!.toLocal()),
                    ),
                    _MiniInfo(
                      icon: Icons.account_box_outlined,
                      label: 'Providers',
                      value: user.providerIds.isEmpty
                          ? '—'
                          : user.providerIds.join(', '),
                    ),
                    _MiniInfo(
                      icon: Icons.verified_outlined,
                      label: 'Email verified',
                      value: user.emailVerified ? 'Yes' : 'No',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SUBSCRIPTION CARD ────────────────────────────────────────────────────

class _SubscriptionCard extends StatelessWidget {
  final AdminUserDetail user;
  const _SubscriptionCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy');
    final usd = NumberFormat.simpleCurrency(decimalDigits: 4);

    final counters = <(_CounterDef, int)>[
      (const _CounterDef('AI Compose', Icons.auto_awesome), user.counter('aiFillCount')),
      (const _CounterDef('AI Refine', Icons.refresh), user.counter('aiRewriteCount')),
      (const _CounterDef('AI Assistant', Icons.smart_toy_outlined), user.counter('editorAiCount')),
      (const _CounterDef('AI Hourly Burst', Icons.bolt_outlined), user.counter('editorAiHourlyCount')),
      (const _CounterDef('Refusals', Icons.block), user.counter('editorAiRefusalCount')),
      (const _CounterDef('Exports', Icons.download_outlined), user.counter('exportCount')),
      (const _CounterDef('Proofread', Icons.spellcheck), user.counter('spellcheckCount')),
      (const _CounterDef('CVs', Icons.description_outlined), user.counter('cvCount')),
      (const _CounterDef('Cover letters', Icons.mail_outline), user.counter('coverLetterCount')),
      (const _CounterDef('Proposals', Icons.assignment_outlined), user.counter('proposalCount')),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Subscription',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.prussianBlue,
                ),
              ),
              const SizedBox(width: 12),
              _PlanBadge(user: user),
              if (user.trialActive) ...[
                const SizedBox(width: 6),
                const _Chip(
                  label: 'TRIAL ACTIVE',
                  bg: AppColors.petalFrost,
                  fg: AppColors.darkRaspberry,
                ),
              ],
              const Spacer(),
              Text(
                'MTD: ${usd.format(user.mtdSpend)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: AppColors.dustyMauve,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 6,
            children: [
              _MiniInfo(
                icon: Icons.event_outlined,
                label: 'Cycle',
                value: user.cycleStart == null
                    ? '—'
                    : '${dateFmt.format(user.cycleStart!.toLocal())} → '
                    '${user.cycleEnd == null ? '—' : dateFmt.format(user.cycleEnd!.toLocal())}',
              ),
              if (user.trialEnd != null)
                _MiniInfo(
                  icon: Icons.hourglass_bottom,
                  label: 'Trial ends',
                  value: dateFmt.format(user.trialEnd!.toLocal()),
                ),
              _MiniInfo(
                icon: Icons.history,
                label: 'Trial used',
                value: user.trialUsed ? 'Yes' : 'No',
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionLabel(label: 'CYCLE COUNTERS'),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 900
                  ? 5
                  : c.maxWidth > 600
                  ? 3
                  : 2;
              const gap = 10.0;
              final w = (c.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: counters
                    .map((entry) => SizedBox(
                  width: w,
                  child: _CounterTile(
                    label: entry.$1.label,
                    icon: entry.$1.icon,
                    value: entry.$2,
                  ),
                ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── ACTIONS CARD ─────────────────────────────────────────────────────────

class _ActionsCard extends StatelessWidget {
  final AdminUserDetail user;
  final WidgetRef ref;
  const _ActionsCard({required this.user, required this.ref});

  bool get _isPro => user.plan == 'pro';

  Future<void> _runAction(
      BuildContext context, {
        required String title,
        required String description,
        required String auditAction,
        required String confirmLabel,
        bool destructive = false,
        bool showDaysInput = false,
        int daysInitial = 30,
        String daysLabel = 'Days',
        required Future<void> Function(int? days) call,
        required String successMessage,
      }) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminConfirmDialog(
        title: title,
        description: description,
        auditAction: auditAction,
        confirmLabel: confirmLabel,
        destructive: destructive,
        showDaysInput: showDaysInput,
        daysInitial: daysInitial,
        daysLabel: daysLabel,
        onConfirm: call,
      ),
    );
    if (ok == true && context.mounted) {
      ref.invalidate(adminUserDetailProvider(user.uid));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: AppColors.darkRaspberry,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailLabel = user.email ?? user.uid;

    final buttons = <Widget>[
      // Grant Pro — hidden for users already on Pro
      if (!_isPro)
        _ActionButton(
          icon: Icons.workspace_premium,
          label: 'Grant Pro',
          primary: true,
          onPressed: () => _runAction(
            context,
            title: 'Grant Pro plan',
            description:
            'Set $emailLabel to the Pro plan for the chosen number '
                'of days. Their subscription end date and billing cycle '
                'will be set accordingly.',
            auditAction: 'adminSetPlan',
            confirmLabel: 'Grant Pro',
            showDaysInput: true,
            daysInitial: 30,
            call: (days) => AdminFunctionsService.setPlan(
              targetUid: user.uid,
              plan: 'pro',
              cycleDays: days ?? 30,
            ),
            successMessage: 'Granted Pro to $emailLabel.',
          ),
        ),

      // Extend Trial — hidden for Pro users (backend rejects anyway)
      if (!_isPro)
        _ActionButton(
          icon: Icons.hourglass_bottom,
          label: 'Extend Trial',
          onPressed: () => _runAction(
            context,
            title: 'Extend trial',
            description:
            'Extend $emailLabel\'s trial by the chosen number of '
                'days. If they have no active trial, a new one starts '
                'from now.',
            auditAction: 'adminExtendTrial',
            confirmLabel: 'Extend',
            showDaysInput: true,
            daysInitial: 7,
            call: (days) => AdminFunctionsService.extendTrial(
              targetUid: user.uid,
              days: days ?? 7,
            ),
            successMessage: 'Trial extended for $emailLabel.',
          ),
        ),

      _ActionButton(
        icon: Icons.restart_alt,
        label: 'Reset Counters',
        onPressed: () => _runAction(
          context,
          title: 'Reset monthly counters',
          description:
          'Zero all cycle counters (AI Compose, AI Refine, AI '
              'Assistant, exports, etc.) for $emailLabel and start a '
              'new 30-day cycle from now.',
          auditAction: 'adminResetCounters',
          confirmLabel: 'Reset',
          call: (_) => AdminFunctionsService.resetCounters(
            targetUid: user.uid,
          ),
          successMessage: 'Counters reset for $emailLabel.',
        ),
      ),

      _ActionButton(
        icon: Icons.bolt_outlined,
        label: 'Reset Hourly Burst',
        onPressed: () => _runAction(
          context,
          title: 'Reset AI Assistant hourly burst',
          description:
          'Clear the AI Assistant hourly burst counter for '
              '$emailLabel so they can use AI Assistant again right '
              'away.',
          auditAction: 'adminResetHourlyBurst',
          confirmLabel: 'Reset',
          call: (_) => AdminFunctionsService.resetHourlyBurst(
            targetUid: user.uid,
          ),
          successMessage: 'Hourly burst reset.',
        ),
      ),

      _ActionButton(
        icon: Icons.block,
        label: 'Reset Refusal',
        onPressed: () => _runAction(
          context,
          title: 'Clear refusal soft-block',
          description:
          'Reset $emailLabel\'s refusal counter to zero. Use this '
              'when you have reviewed their conversation and want to '
              'lift the soft-block.',
          auditAction: 'adminResetRefusalCount',
          confirmLabel: 'Reset',
          call: (_) => AdminFunctionsService.resetRefusalCount(
            targetUid: user.uid,
          ),
          successMessage: 'Refusal counter reset.',
        ),
      ),

      // Revoke Pro — only shown for Pro users
      if (_isPro)
        _ActionButton(
          icon: Icons.cancel_outlined,
          label: 'Revoke Pro → Free',
          destructive: true,
          onPressed: () => _runAction(
            context,
            title: 'Revoke Pro plan',
            description:
            'Set $emailLabel to the Free plan. Their subscription '
                'end date will be cleared. Pre-paid period is NOT '
                'refunded automatically — handle that separately.',
            auditAction: 'adminSetPlan',
            confirmLabel: 'Revoke',
            destructive: true,
            call: (_) => AdminFunctionsService.setPlan(
              targetUid: user.uid,
              plan: 'free',
            ),
            successMessage: 'Pro revoked for $emailLabel.',
          ),
        ),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin actions',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.prussianBlue,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'All actions write to the audit log.',
            style: TextStyle(fontSize: 12, color: AppColors.slateGrey),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 10, children: buttons),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final bool destructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
      );
    }
    if (destructive) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dangerRed,
          foregroundColor: AppColors.white,
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

// ─── COUNTERS ─────────────────────────────────────────────────────────────

class _CounterDef {
  final String label;
  final IconData icon;
  const _CounterDef(this.label, this.icon);
}

class _CounterTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  const _CounterTile({
    required this.label,
    required this.icon,
    required this.value,
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
            '$value',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.prussianBlue,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── LIFETIME CARD ────────────────────────────────────────────────────────

class _LifetimeCard extends StatelessWidget {
  final AdminUserDetail user;
  const _LifetimeCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy · HH:mm');
    final usd = NumberFormat.simpleCurrency(decimalDigits: 4);
    final compact = NumberFormat.compact();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lifetime totals',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.prussianBlue,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _MiniInfo(
                icon: Icons.login,
                label: 'Last login',
                value: user.lastLoginAt == null
                    ? '—'
                    : dateFmt.format(user.lastLoginAt!.toLocal()),
              ),
              _MiniInfo(
                icon: Icons.bolt,
                label: 'Last active',
                value: user.lastActiveAt == null
                    ? '—'
                    : dateFmt.format(user.lastActiveAt!.toLocal()),
              ),
              _MiniInfo(
                icon: Icons.savings_outlined,
                label: 'Total spend',
                value: usd.format(user.summaryNum('totalCostUsd')),
              ),
              _MiniInfo(
                icon: Icons.token_outlined,
                label: 'Total tokens',
                value: compact.format(user.summaryInt('totalTokensUsed')),
              ),
              _MiniInfo(
                icon: Icons.auto_awesome,
                label: 'AI calls',
                value:
                '${user.summaryInt('totalAiFills')} compose · ${user.summaryInt('totalAiRewrites')} refine · ${user.summaryInt('totalAiEdits')} assistant',
              ),
              _MiniInfo(
                icon: Icons.download,
                label: 'Exports',
                value: '${user.summaryInt('totalExports')}',
              ),
              _MiniInfo(
                icon: Icons.description_outlined,
                label: 'Docs created',
                value:
                '${user.summaryInt('totalCvsCreated')} CV · ${user.summaryInt('totalCoverLettersCreated')} CL · ${user.summaryInt('totalProposalsCreated')} proposals',
              ),
              _MiniInfo(
                icon: Icons.login,
                label: 'Logins',
                value: '${user.summaryInt('loginCount')}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── SHARED ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
    return Column(
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
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.prussianBlue,
          ),
        ),
      ],
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
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
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

class _PlanBadge extends StatelessWidget {
  final AdminUserDetail user;
  const _PlanBadge({required this.user});
  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    if (user.plan == 'pro') {
      bg = AppColors.darkRaspberry;
      fg = AppColors.white;
    } else if (user.plan == 'trial') {
      bg = AppColors.magentaBloom;
      fg = AppColors.white;
    } else {
      bg = AppColors.petalFrost;
      fg = AppColors.darkRaspberry;
    }
    return _Chip(label: user.plan.toUpperCase(), bg: bg, fg: fg);
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.slateGrey,
      ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.dangerRed.withValues(alpha: 0.3)),
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