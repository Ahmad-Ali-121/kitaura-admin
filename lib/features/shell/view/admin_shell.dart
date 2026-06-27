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

class _AdminSidebar extends ConsumerWidget {
  const _AdminSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.prussianBlue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo block
          Padding(
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
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
          ),

          const Divider(
              color: AppColors.slateGrey, height: 1, thickness: 0.3),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                // ignore: prefer_const_constructors
                _SidebarSection(label: 'OVERVIEW'),
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  route: '/admin',
                  active: location == '/admin',
                ),
                const _SidebarSection(label: 'MANAGE'),
                _SidebarItem(
                  icon: Icons.people_outline,
                  label: 'Users',
                  route: '/admin/users',
                  active: location.startsWith('/admin/users'),
                  disabled: true,
                ),
                _SidebarItem(
                  icon: Icons.auto_awesome_outlined,
                  label: 'AI Activity',
                  route: '/admin/ai',
                  active: location.startsWith('/admin/ai'),
                  disabled: true,
                ),
                _SidebarItem(
                  icon: Icons.attach_money,
                  label: 'Finance',
                  route: '/admin/finance',
                  active: location.startsWith('/admin/finance'),
                  disabled: true,
                ),
                const _SidebarSection(label: 'CONFIG'),
                _SidebarItem(
                  icon: Icons.tune,
                  label: 'Plan Limits',
                  route: '/admin/config/limits',
                  active: location == '/admin/config/limits',
                  disabled: true,
                ),
                _SidebarItem(
                  icon: Icons.price_change_outlined,
                  label: 'Pricing',
                  route: '/admin/config/pricing',
                  active: location == '/admin/config/pricing',
                  disabled: true,
                ),
                _SidebarItem(
                  icon: Icons.toggle_on_outlined,
                  label: 'Feature Flags',
                  route: '/admin/config/feature-flags',
                  active: location == '/admin/config/feature-flags',
                  disabled: true,
                ),
                _SidebarItem(
                  icon: Icons.campaign_outlined,
                  label: 'Announcements',
                  route: '/admin/config/announcements',
                  active: location == '/admin/config/announcements',
                  disabled: true,
                ),
                const _SidebarSection(label: 'AUDIT'),
                _SidebarItem(
                  icon: Icons.history,
                  label: 'Audit Log',
                  route: '/admin/audit',
                  active: location == '/admin/audit',
                  disabled: true,
                ),
              ],
            ),
          ),

          // Sign out
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: () => ref.read(adminAuthProvider.notifier).signOut(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
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
          ),
        ],
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String label;
  const _SidebarSection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
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

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool active;
  final bool disabled;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.active,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = disabled
        ? AppColors.slateGrey
        : (active ? AppColors.white : AppColors.almondSilk);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: active
            ? AppColors.magentaBloom.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: disabled ? null : () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
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
                if (disabled)
                  const Text(
                    'soon',
                    style: TextStyle(
                      color: AppColors.slateGrey,
                      fontSize: 9,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.5,
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
    if (location.startsWith('/admin/ai')) return 'AI Activity';
    if (location.startsWith('/admin/finance')) return 'Finance';
    if (location.startsWith('/admin/config')) return 'Config';
    if (location.startsWith('/admin/audit')) return 'Audit Log';
    return 'Admin';
  }
}