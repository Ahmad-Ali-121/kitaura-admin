import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/controller/admin_auth_controller.dart';
import '../../features/auth/view/admin_login_screen.dart';
import '../../features/dashboard/view/admin_dashboard_screen.dart';
import '../../features/shell/view/admin_shell.dart';

/// Simple ChangeNotifier that fires whenever auth state changes.
/// GoRouter uses this to re-evaluate redirects.
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
      // Wait for auth to settle before redirecting
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
        ],
      ),
    ],
  );
});