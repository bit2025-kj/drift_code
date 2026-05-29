import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/providers/admin_provider.dart';
import 'package:nafa_edu/providers/auth_provider.dart';
import 'package:nafa_edu/screens/admin/admin_dashboard_screen.dart';
import 'package:nafa_edu/screens/admin/users_list_screen.dart';
import 'package:nafa_edu/screens/admin/reports_screen.dart';
import 'package:nafa_edu/screens/admin/teacher_requests_admin_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  static const _screens = [
    AdminDashboardScreen(),
    UsersListScreen(),
    ReportsScreen(),
    TeacherRequestsAdminScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final pendingReports = ref.watch(adminStatsProvider).maybeWhen(
          data: (s) => s.pendingReports,
          orElse: () => 0,
        );
    final pendingRequests = ref.watch(adminStatsProvider).maybeWhen(
          data: (s) => s.pendingTeacherRequests,
          orElse: () => 0,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              // Stack cleanup handled by _AuthGate's ref.listen.
            },
          ),
        ],
      ),
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          const NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Utilisateurs'),
          NavigationDestination(
            icon: Badge(label: pendingReports > 0 ? Text('$pendingReports') : null, child: const Icon(Icons.flag_outlined)),
            selectedIcon: Badge(label: pendingReports > 0 ? Text('$pendingReports') : null, child: const Icon(Icons.flag)),
            label: 'Signalements',
          ),
          NavigationDestination(
            icon: Badge(label: pendingRequests > 0 ? Text('$pendingRequests') : null, child: const Icon(Icons.school_outlined)),
            selectedIcon: Badge(label: pendingRequests > 0 ? Text('$pendingRequests') : null, child: const Icon(Icons.school)),
            label: 'Profs',
          ),
        ],
      ),
    );
  }
}
