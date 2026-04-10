import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    final routes = ['/home', '/call', '/messages', '/play', '/my-profile'];
    if (index != currentIndex) {
      // Use pushNamedAndRemoveUntil so there's always a clean nav stack.
      // This prevents blank screens when pressing back.
      // We keep the route predicate as false to clear the stack, then the
      // new screen becomes the root. The WillPopScope / PopScope in each
      // bottom-nav screen handles the system back button.
      Navigator.pushNamedAndRemoveUntil(
        context,
        routes[index],
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark.withOpacity(0.95) : Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                index: 0,
                currentIndex: currentIndex,
                onTap: () => _onItemTapped(context, 0),
              ),
              _NavItem(
                icon: Icons.call_rounded,
                index: 1,
                currentIndex: currentIndex,
                onTap: () => _onItemTapped(context, 1),
              ),
              _NavItem(
                icon: Icons.chat_bubble_rounded,
                index: 2,
                currentIndex: currentIndex,
                onTap: () => _onItemTapped(context, 2),
              ),
              _NavItem(
                icon: Icons.smart_display_rounded,
                index: 3,
                currentIndex: currentIndex,
                onTap: () => _onItemTapped(context, 3),
              ),
              GestureDetector(
                onTap: () => _onItemTapped(context, 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: currentIndex == 4 ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl:
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuCCphgPcz225mSJx5UUnQf3LRfEjXZ95vXgbNUEASwrhXMdPjJdc1jIMzYe8ZVAnJrHE9XPJTKaaIC7RL31x-CMLRK1q2j_gXTDwThBkmGWnm6cMkZIvqECe_qkQlMbqDXG39bMZgoxthG5kR4q5GKjFrTJW5QQE14dfrXSzvMaXm483i2bLmBcqEM6eWdf9_EVDjvAox2zd257BJG3v2t9bA41RPKx8tPDN38O7RAjaAFeolU329Idfe3E6MLFxc9rOs20FIOio28',
                          fit: BoxFit.cover,
                          placeholder: (c, u) => Container(color: Colors.grey.shade200),
                          errorWidget: (c, u, e) => const Icon(Icons.person),
                        ),
                      ),
                    ),
                    if (currentIndex == 4)
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 28,
            color: isActive ? AppColors.primary : AppColors.textSecondaryLight,
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}
