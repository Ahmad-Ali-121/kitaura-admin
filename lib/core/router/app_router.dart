import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/controller/admin_auth_controller.dart';
import '../../features/auth/view/admin_login_screen.dart';
import '../../features/dashboard/view/admin_dashboard_screen.dart';
import '../../features/shell/view/admin_shell.dart';
import '../../features/users/view/users_list_screen.dart';
import '../../features/users/view/user_detail_screen.dart';
import '../../features/audit/view/audit_log_screen.dart';
import '../../features/config/limits/view/plan_limits_editor_screen.dart';
import '../../features/config/pricing/view/pricing_editor_screen.dart';
import '../../features/config/pro_templates/view/pro_templates_editor_screen.dart';
import '../../features/config/feature_flags/view/feature_flags_screen.dart';
import '../../features/config/announcements/view/announcement_editor_screen.dart';
import '../../features/ai/view/ai_activity_screen.dart';
import '../../features/ai/view/ai_failures_screen.dart';

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(adminAuthProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/admin',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(adminAuthProvider);
      if (!auth.initialized) return null;

      final atLogin = state.matchedLocation == '/login';
      if (!auth.isAuthenticated) {
        return atLogin ? null : '/login';
      }
      if (atLogin) return '/admin';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const UsersListScreen(),
          ),
          GoRoute(
            path: '/admin/users/:uid',
            builder: (context, state) => UserDetailScreen(
              uid: state.pathParameters['uid'] ?? '',
            ),
          ),
          GoRoute(
            path: '/admin/audit',
            builder: (context, state) => const AuditLogScreen(),
          ),
          GoRoute(
            path: '/admin/config/limits',
            builder: (context, state) => const PlanLimitsEditorScreen(),
          ),
          GoRoute(
            path: '/admin/config/pricing',
            builder: (context, state) => const PricingEditorScreen(),
          ),
          GoRoute(
            path: '/admin/config/pro-templates',
            builder: (context, state) => const ProTemplatesEditorScreen(),
          ),
          GoRoute(
            path: '/admin/config/feature-flags',
            builder: (context, state) => const FeatureFlagsScreen(),
          ),
          GoRoute(
            path: '/admin/config/announcements',
            builder: (context, state) => const AnnouncementEditorScreen(),
          ),
          GoRoute(
            path: '/admin/ai',
            builder: (context, state) => const AiActivityScreen(),
          ),
          GoRoute(
            path: '/admin/ai/failures',
            builder: (context, state) => const AiFailuresScreen(),
          ),
        ],
      ),
    ],
  );
});