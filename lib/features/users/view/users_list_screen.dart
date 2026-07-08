import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../controller/admin_users_controller.dart';
import '../model/admin_user_summary.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usersListProvider);
    final ctrl = ref.read(usersListProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(total: state.total, loading: state.loading),
          const SizedBox(height: 20),
          _Toolbar(
            searchController: _searchCtrl,
            planFilter: state.planFilter,
            sortBy: state.sortBy,
            onSearchChanged: ctrl.setSearch,
            onPlanChanged: ctrl.setPlanFilter,
            onSortChanged: ctrl.setSortBy,
            onRefresh: ctrl.load,
            loading: state.loading,
          ),
          const SizedBox(height: 14),
          if (state.error != null) ...[
            _ErrorBlock(error: state.error!),
            const SizedBox(height: 14),
          ],
          _UsersTable(items: state.items, loading: state.loading),
          const SizedBox(height: 14),
          _PaginationBar(state: state, onPage: ctrl.setPage),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int total;
  final bool loading;
  const _Header({required this.total, required this.loading});

  @override
  Widget build(BuildContext context) {
    final count = NumberFormat.compact().format(total);
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Users',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.prussianBlue,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'All registered KitAura accounts',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.slateGrey,
                ),
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
              '$count total',
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

// ─── TOOLBAR — fixed Spacer-in-Wrap bug ───────────────────────────────────

class _Toolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String planFilter;
  final String sortBy;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onPlanChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onRefresh;
  final bool loading;

  const _Toolbar({
    required this.searchController,
    required this.planFilter,
    required this.sortBy,
    required this.onSearchChanged,
    required this.onPlanChanged,
    required this.onSortChanged,
    required this.onRefresh,
    required this.loading,
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
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search by email or UID…',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search,
                          size: 18, color: AppColors.slateGrey),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.close,
                            size: 16,
                            color: AppColors.slateGrey),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                          : null,
                    ),
                  ),
                ),
                _PlanChips(value: planFilter, onChanged: onPlanChanged),
                DropdownButton<String>(
                  value: sortBy,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      size: 18, color: AppColors.slateGrey),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.prussianBlue,
                    fontFamily: 'OpenSans',
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'signupDesc',
                        child: Text('Newest signups')),
                    DropdownMenuItem(
                        value: 'signupAsc',
                        child: Text('Oldest signups')),
                    DropdownMenuItem(
                        value: 'lastActive',
                        child: Text('Recently active')),
                    DropdownMenuItem(
                        value: 'spend',
                        child: Text('Highest MTD spend')),
                    DropdownMenuItem(
                        value: 'docs', child: Text('Most docs')),
                  ],
                  onChanged: (v) => v == null ? null : onSortChanged(v),
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

class _PlanChips extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _PlanChips({required this.value, required this.onChanged});

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
        chip('All', 'all'),
        const SizedBox(width: 6),
        chip('Guest', 'guest'),
        const SizedBox(width: 6),
        chip('Free', 'free'),
        const SizedBox(width: 6),
        chip('Trial', 'trial'),
        const SizedBox(width: 6),
        chip('Pro', 'pro'),
      ],
    );
  }
}

// ─── TABLE ────────────────────────────────────────────────────────────────

class _UsersTable extends StatelessWidget {
  final List<AdminUserSummary> items;
  final bool loading;
  const _UsersTable({required this.items, required this.loading});

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
                Expanded(flex: 4, child: Text('USER', style: _h)),
                Expanded(flex: 2, child: Text('PLAN', style: _h)),
                Expanded(flex: 2, child: Text('SIGNUP', style: _h)),
                Expanded(flex: 2, child: Text('LAST ACTIVE', style: _h)),
                Expanded(
                  flex: 1,
                  child:
                  Text('DOCS', style: _h, textAlign: TextAlign.right),
                ),
                Expanded(
                  flex: 2,
                  child: Text('MTD SPEND',
                      style: _h, textAlign: TextAlign.right),
                ),
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
                  'No users match your filters.',
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
                    thickness: 0.4),
              _UserRow(user: items[i]),
            ],
        ],
      ),
    );
  }
}

class _UserRow extends StatefulWidget {
  final AdminUserSummary user;
  const _UserRow({required this.user});

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy');
    final relFmt = DateFormat('MMM d, HH:mm');
    final usd = NumberFormat.simpleCurrency(decimalDigits: 4);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.go('/admin/users/${widget.user.uid}'),
        child: Container(
          color: _hover ? AppColors.lavenderBlush : Colors.transparent,
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.email ?? '(no email)',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.prussianBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.user.uid,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.slateGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(flex: 2, child: _PlanBadge(user: widget.user)),
              Expanded(
                flex: 2,
                child: Text(
                  widget.user.signupAt == null
                      ? '—'
                      : dateFmt.format(widget.user.signupAt!.toLocal()),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.prussianBlue),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.user.lastActiveAt == null
                      ? '—'
                      : relFmt.format(widget.user.lastActiveAt!.toLocal()),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.prussianBlue),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${widget.user.docCount}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.prussianBlue),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  usd.format(widget.user.mtdSpend),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.prussianBlue,
                  ),
                ),
              ),
              const SizedBox(
                width: 24,
                child: Icon(
                  Icons.chevron_right,
                  color: AppColors.slateGrey,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final AdminUserSummary user;
  const _PlanBadge({required this.user});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = user.plan.toUpperCase();
    if (user.plan == 'pro') {
      bg = AppColors.darkRaspberry;
      fg = AppColors.white;
    } else if (user.plan == 'trial') {
      bg = AppColors.magentaBloom;
      fg = AppColors.white;
    } else if (user.plan == 'guest') {
      bg = AppColors.dustyMauve;
      fg = AppColors.white;
    } else {
      bg = AppColors.petalFrost;
      fg = AppColors.darkRaspberry;
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final UsersListState state;
  final ValueChanged<int> onPage;
  const _PaginationBar({required this.state, required this.onPage});

  @override
  Widget build(BuildContext context) {
    if (state.total == 0) return const SizedBox.shrink();
    final pageDisplay = state.page + 1;
    final start = state.page * state.pageSize + 1;
    final end = (start + state.items.length - 1)
        .clamp(start, state.total);
    return Row(
      children: [
        Text(
          'Showing $start–$end of ${state.total}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.slateGrey,
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed:
          state.page == 0 ? null : () => onPage(state.page - 1),
          icon: const Icon(Icons.chevron_left, size: 16),
          label: const Text('Prev'),
        ),
        const SizedBox(width: 8),
        Text(
          'Page $pageDisplay of ${state.totalPages}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.prussianBlue,
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed:
          state.hasMore ? () => onPage(state.page + 1) : null,
          icon: const Icon(Icons.chevron_right, size: 16),
          label: const Text('Next'),
        ),
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

const _h = TextStyle(
  fontFamily: 'Poppins',
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 1,
  color: AppColors.slateGrey,
);