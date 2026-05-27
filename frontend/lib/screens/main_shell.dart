import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/providers/notification_provider.dart';
import 'package:nafa_edu/screens/home/home_screen.dart';
import 'package:nafa_edu/screens/banque/banque_screen.dart';
import 'package:nafa_edu/screens/quiz/quiz_screen.dart';
import 'package:nafa_edu/screens/forum/forum_screen.dart';
import 'package:nafa_edu/screens/marketplace/marketplace_screen.dart';
import 'package:nafa_edu/screens/profil/profil_screen.dart';
import 'package:nafa_edu/widgets/common/offline_banner.dart';

// Providers de navigation globale
final tabIndexProvider = StateProvider<int>((ref) => 0);
final banqueLevelFilterProvider = StateProvider<int?>((ref) => null);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  static const _screens = [
    HomeScreen(),
    BanqueScreen(),
    QuizScreen(),
    ForumScreen(),
    MarketplaceScreen(),
    ProfilScreen(),
  ];

  static const _navItems = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Accueil'),
    _NavItem(icon: Icons.library_books_outlined, activeIcon: Icons.library_books_rounded, label: 'Banque'),
    _NavItem(icon: Icons.quiz_outlined, activeIcon: Icons.quiz_rounded, label: 'Quiz'),
    _NavItem(icon: Icons.forum_outlined, activeIcon: Icons.forum_rounded, label: 'Forum'),
    _NavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, label: 'Marché'),
    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(tabIndexProvider);

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: IndexedStack(index: currentIndex, children: MainShell._screens),
          ),
        ],
      ),
      bottomNavigationBar: _NavBar(currentIndex: currentIndex),
    );
  }
}

class _NavBar extends ConsumerWidget {
  final int currentIndex;
  const _NavBar({required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: MainShell._navItems.asMap().entries.map((e) {
              final selected = currentIndex == e.key;
              final item = e.value;
              // Show notification badge on Accueil tab (index 0)
              final showBadge = e.key == 0 && unread > 0;
              return Expanded(
                child: GestureDetector(
                  onTap: () => ref.read(tabIndexProvider.notifier).state = e.key,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary.withValues(alpha:0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              selected ? item.activeIcon : item.icon,
                              size: 22,
                              color: selected ? AppColors.primary : const Color(0xFFADB5BD),
                            ),
                          ),
                          if (showBadge)
                            Positioned(
                              top: -2,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFA5252),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  unread > 9 ? '9+' : '$unread',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          color: selected ? AppColors.primary : const Color(0xFFADB5BD),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
