import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/controller/admin_auth_controller.dart';

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(adminAuthProvider);

    // Hold rendering until Firebase Auth resolves. Prevents the dashboard
    // from flashing before the router knows whether to redirect to login.
    if (!auth.initialized) {
      return MaterialApp(
        title: 'KitAura Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _AdminBootSplash(),
      );
    }

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'KitAura Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

class _AdminBootSplash extends StatelessWidget {
  const _AdminBootSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(Color(0xFF831843)),
          ),
        ),
      ),
    );
  }
}