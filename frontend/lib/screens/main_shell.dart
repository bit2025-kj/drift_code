import 'dart:ui';

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

// Providers
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
      extendBody: true,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: MainShell._screens,
            ),
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 25,
              sigmaY: 25,
            ),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.70),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: MainShell._navItems.asMap().entries.map((e) {
                  final index = e.key;
                  final item = e.value;
                  final selected = currentIndex == index;
                  final showBadge = index == 0 && unread > 0;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          ref.read(tabIndexProvider.notifier).state = index,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  selected
                                      ? item.activeIcon
                                      : item.icon,
                                  size: 22,
                                  color: selected
                                      ? AppColors.primary
                                      : const Color(0xFF6B7280),
                                ),
                              ),

                              if (showBadge)
                                Positioned(
                                  top: -3,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFA5252),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      unread > 9 ? '9+' : '$unread',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 3),

                          Text(
                            item.label,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AppColors.primary
                                  : const Color(0xFF6B7280),
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
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}