import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/providers/auth_provider.dart';
import 'package:nafa_edu/screens/auth/login_screen.dart';
import 'package:nafa_edu/screens/main_shell.dart';
import 'package:nafa_edu/screens/admin/admin_shell.dart';

class NafaEduApp extends ConsumerWidget {
  const NafaEduApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Nafa Edu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Vide la stack Navigator dès que la session expire ou que logout() est appelé,
    // peu importe depuis quel écran (Settings, Admin, expiration token…).
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.status != AuthStatus.unauthenticated &&
          next.status == AuthStatus.unauthenticated) {
        Navigator.of(context, rootNavigator: true)
            .popUntil((route) => route.isFirst);
      }
    });

    final auth = ref.watch(authProvider);
    switch (auth.status) {
      case AuthStatus.loading:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('N', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primary)),
                SizedBox(height: 8),
                Text('Nafa Edu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
                SizedBox(height: 24),
                CircularProgressIndicator(color: AppColors.primary),
              ],
            ),
          ),
        );
      case AuthStatus.authenticated:
        return auth.user?.isAdmin == true ? const AdminShell() : const MainShell();
      case AuthStatus.unauthenticated:
        return const MainShell(); // Guest access
    }
  }
}
