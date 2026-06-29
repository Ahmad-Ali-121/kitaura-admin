import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/controller/admin_auth_controller.dart';

/// Wraps every authenticated /admin/* route with sidebar + top bar.
class AdminShell extends ConsumerWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.warmGrey,
      body: Row(
        children: [
          const _AdminSidebar(),
          Expanded(
            child: Column(
              children: [
                const _AdminTopBar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SIDEBAR ─────────────────────────────────────────────────────────────

/// Lightweight data class for a single nav row.
class _NavItemData {
  final IconData icon;
  final String label;
  final String route;
  const _NavItemData(this.icon, this.label, this.route);
}

class _AdminSidebar extends ConsumerStatefulWidget {
  const _AdminSidebar();

  @override
  ConsumerState<_AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends ConsumerState<_AdminSidebar> {
  // Expanded state per collapsible section. Persists across route changes
  // within the same session (the shell widget is kept alive by GoRouter).
  final Map<String, bool> _expanded = {
    'AI': true,
    'FINANCE': true,
    'CONFIG': true,
  };

  // ─── Nav data ─────────────────────────────────────────────────────────

  static const _overview = [
    _NavItemData(Icons.dashboard_outlined, 'Dashboard', '/admin'),
  ];

  static const _manage = [
    _NavItemData(Icons.people_outline, 'Users', '/admin/users'),
    _NavItemData(Icons.folder_outlined, 'Documents', '/admin/documents'),
  ];

  static const _ai = [
    _NavItemData(Icons.auto_awesome_outlined, 'Activity', '/admin/ai'),
    _NavItemData(Icons.error_outline, 'Failures', '/admin/ai/failures'),
    _NavItemData(Icons.block, 'Refusals', '/admin/ai/refusals'),
    _NavItemData(Icons.shield_outlined, 'Abuse Monitor', '/admin/abuse'),
  ];

  static const _finance = [
    _NavItemData(Icons.attach_money, 'Overview', '/admin/finance'),
    _NavItemData(Icons.leaderboard_outlined, 'By User', '/admin/finance/by-user'),
    _NavItemData(Icons.pie_chart_outline, 'By Feature', '/admin/finance/by-feature'),
  ];

  static const _config = [
    _NavItemData(Icons.tune, 'Plan Limits', '/admin/config/limits'),
    _NavItemData(Icons.price_change_outlined, 'Pricing', '/admin/config/pricing'),
    _NavItemData(Icons.workspace_premium, 'Pro Templates',
        '/admin/config/pro-templates'),
    _NavItemData(Icons.toggle_on_outlined, 'Feature Flags',
        '/admin/config/feature-flags'),
    _NavItemData(Icons.campaign_outlined, 'Announcements',
        '/admin/config/announcements'),
  ];

  static const _audit = [
    _NavItemData(Icons.history, 'Audit Log', '/admin/audit'),
  ];

  /// All known routes used to compute the best-matching active item.
  static const _allRoutes = [
    '/admin',
    '/admin/users',
    '/admin/documents',
    '/admin/ai',
    '/admin/ai/failures',
    '/admin/ai/refusals',
    '/admin/abuse',
    '/admin/finance',
    '/admin/finance/by-user',
    '/admin/finance/by-feature',
    '/admin/config/limits',
    '/admin/config/pricing',
    '/admin/config/pro-templates',
    '/admin/config/feature-flags',
    '/admin/config/announcements',
    '/admin/audit',
  ];

  /// Returns the longest route prefix that matches the current location.
  /// So `/admin/users/abc123` resolves to `/admin/users`, and
  /// `/admin/ai/failures` resolves to itself (not `/admin/ai`).
  String _findActiveRoute(String location) {
    var best = '';
    for (final r in _allRoutes) {
      final isMatch = r == location || location.startsWith('$r/');
      if (isMatch && r.length > best.length) {
        best = r;
      }
    }
    return best;
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final activeRoute = _findActiveRoute(location);

    return Container(
      width: 250,
      decoration: const BoxDecoration(color: AppColors.prussianBlue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLogo(),
          const Divider(
            color: AppColors.slateGrey,
            height: 1,
            thickness: 0.3,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildFlatSection('OVERVIEW', _overview, activeRoute),
                _buildFlatSection('MANAGE', _manage, activeRoute),
                _buildCollapsibleSection('AI', _ai, activeRoute),
                _buildCollapsibleSection('FINANCE', _finance, activeRoute),
                _buildCollapsibleSection('CONFIG', _config, activeRoute),
                _buildFlatSection('AUDIT', _audit, activeRoute),
              ],
            ),
          ),
          _buildSignOut(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Row(
        children: [
          const Text(
            'KITAURA',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: 1.5,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.magentaBloom,
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text(
              'ADMIN',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 1,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatSection(
      String label,
      List<_NavItemData> items,
      String activeRoute,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SidebarSection(label: label),
        ...items.map((it) => _SidebarItem(
          icon: it.icon,
          label: it.label,
          route: it.route,
          active: it.route == activeRoute,
        )),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildCollapsibleSection(
      String key,
      List<_NavItemData> items,
      String activeRoute,
      ) {
    final expanded = _expanded[key] ?? true;
    final hasActiveChild = items.any((it) => it.route == activeRoute);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CollapsibleSectionHeader(
          label: key,
          expanded: expanded,
          hasActiveChild: hasActiveChild,
          onTap: () => setState(() => _expanded[key] = !expanded),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          curve: Curves.easeInOut,
          child: ClipRect(
            child: expanded
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items
                  .map((it) => _SidebarItem(
                icon: it.icon,
                label: it.label,
                route: it.route,
                active: it.route == activeRoute,
              ))
                  .toList(),
            )
                : const SizedBox(width: double.infinity),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildSignOut() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: () => ref.read(adminAuthProvider.notifier).signOut(),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: const Row(
            children: [
              Icon(Icons.logout,
                  color: AppColors.almondSilk, size: 18),
              SizedBox(width: 12),
              Text(
                'Sign out',
                style: TextStyle(
                  color: AppColors.almondSilk,
                  fontSize: 13,
                  fontFamily: 'OpenSans',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SECTION HEADERS ─────────────────────────────────────────────────────

/// Non-interactive section header for flat (non-collapsible) sections.
class _SidebarSection extends StatelessWidget {
  final String label;
  const _SidebarSection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: AppColors.slateGrey,
        ),
      ),
    );
  }
}

/// Tappable header for collapsible sections. Shows a chevron that rotates
/// to indicate expand/collapse state. Label shifts brighter when any
/// child is active so the section reads as "you're in here" even when
/// collapsed.
class _CollapsibleSectionHeader extends StatelessWidget {
  final String label;
  final bool expanded;
  final bool hasActiveChild;
  final VoidCallback onTap;

  const _CollapsibleSectionHeader({
    required this.label,
    required this.expanded,
    required this.hasActiveChild,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor =
    hasActiveChild ? AppColors.white : AppColors.slateGrey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 4),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: labelColor,
                ),
              ),
              if (hasActiveChild) ...[
                const SizedBox(width: 6),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.magentaBloom,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              const Spacer(),
              AnimatedRotation(
                turns: expanded ? 0 : -0.25,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                child: Icon(
                  Icons.expand_more,
                  size: 14,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SIDEBAR ITEM ────────────────────────────────────────────────────────

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool active;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.white : AppColors.almondSilk;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: active
            ? AppColors.magentaBloom.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: active
            ? Border(
          left: BorderSide(
            color: AppColors.magentaBloom,
            width: 2,
          ),
        )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(icon, color: color, size: 17),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontFamily: 'OpenSans',
                      fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── TOP BAR ─────────────────────────────────────────────────────────────

class _AdminTopBar extends ConsumerWidget {
  const _AdminTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(adminAuthProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final title = _titleForRoute(location);

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.almondSilk, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.prussianBlue,
            ),
          ),
          const Spacer(),
          if (auth.user != null) ...[
            Text(
              auth.user!.email ?? '',
              style: const TextStyle(
                color: AppColors.slateGrey,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.darkRaspberry,
              child: Text(
                (auth.user!.email?.substring(0, 1).toUpperCase() ?? '?'),
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _titleForRoute(String location) {
    if (location == '/admin') return 'Dashboard';
    if (location.startsWith('/admin/users')) return 'Users';
    if (location.startsWith('/admin/documents')) return 'Documents';
    if (location.startsWith('/admin/ai/failures')) return 'AI Failures';
    if (location.startsWith('/admin/ai/refusals')) return 'AI Refusals';
    if (location.startsWith('/admin/ai')) return 'AI Activity';
    if (location.startsWith('/admin/abuse')) return 'Abuse Monitor';
    if (location.startsWith('/admin/finance/by-user')) return 'Cost by User';
    if (location.startsWith('/admin/finance/by-feature')) {
      return 'Cost by Feature';
    }
    if (location.startsWith('/admin/finance')) return 'Cost Overview';
    if (location.startsWith('/admin/config/limits')) return 'Plan Limits';
    if (location.startsWith('/admin/config/pricing')) return 'Pricing';
    if (location.startsWith('/admin/config/pro-templates')) {
      return 'Pro Templates';
    }
    if (location.startsWith('/admin/config/feature-flags')) {
      return 'Feature Flags';
    }
    if (location.startsWith('/admin/config/announcements')) {
      return 'Announcements';
    }
    if (location.startsWith('/admin/audit')) return 'Audit Log';
    return 'Admin';
  }
}