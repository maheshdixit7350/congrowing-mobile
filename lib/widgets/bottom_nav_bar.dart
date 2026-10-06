import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_colors.dart';
import '../services/user_service.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    final routes = ['/home', '/call', '/messages', '/play', '/my-profile'];
    if (index != currentIndex) {
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

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F1629).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AnimatedNavItem(
                    icon: Icons.home_rounded,
                    outlineIcon: Icons.home_outlined,
                    label: 'Home',
                    index: 0,
                    currentIndex: currentIndex,
                    onTap: () => _onItemTapped(context, 0),
                    isDark: isDark,
                  ),
                  _AnimatedNavItem(
                    icon: Icons.call_rounded,
                    outlineIcon: Icons.call_outlined,
                    label: 'Connect',
                    index: 1,
                    currentIndex: currentIndex,
                    onTap: () => _onItemTapped(context, 1),
                    isDark: isDark,
                  ),
                  _AnimatedNavItem(
                    icon: Icons.chat_bubble_rounded,
                    outlineIcon: Icons.chat_bubble_outline_rounded,
                    label: 'Chat',
                    index: 2,
                    currentIndex: currentIndex,
                    onTap: () => _onItemTapped(context, 2),
                    isDark: isDark,
                  ),
                  _AnimatedNavItem(
                    icon: Icons.lightbulb_rounded,
                    outlineIcon: Icons.lightbulb_outline_rounded,
                    label: 'Play',
                    index: 3,
                    currentIndex: currentIndex,
                    onTap: () => _onItemTapped(context, 3),
                    isDark: isDark,
                  ),
                  _ProfileNavItem(
                    index: 4,
                    currentIndex: currentIndex,
                    onTap: () => _onItemTapped(context, 4),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedNavItem extends StatefulWidget {
  final IconData icon;
  final IconData outlineIcon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;
  final bool isDark;

  const _AnimatedNavItem({
    required this.icon,
    required this.outlineIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get isActive => widget.index == widget.currentIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? 16 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isActive ? widget.icon : widget.outlineIcon,
                  key: ValueKey(isActive),
                  size: 22,
                  color: isActive
                      ? AppColors.primary
                      : (widget.isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: isActive
                    ? Row(
                        children: [
                          const SizedBox(width: 6),
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileNavItem extends StatefulWidget {
  final int index;
  final int currentIndex;
  final VoidCallback onTap;
  final bool isDark;

  const _ProfileNavItem({
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_ProfileNavItem> createState() => _ProfileNavItemState();
}

class _ProfileNavItemState extends State<_ProfileNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get isActive => widget.index == widget.currentIndex;

  @override
  Widget build(BuildContext context) {
    final user = UserService.instance.currentUser;
    final initial = user?.name.isNotEmpty == true
        ? user!.name[0].toUpperCase()
        : 'U';

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isActive ? AppColors.primaryGradient : null,
                  color: isActive
                      ? null
                      : (widget.isDark
                          ? AppColors.cardDarkElevated
                          : AppColors.cardLightElevated),
                  border: isActive
                      ? null
                      : Border.all(
                          color: widget.isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight,
                          width: 1.5,
                        ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: ClipOval(
                  child: user?.avatarUrl != null &&
                          user!.avatarUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: user.avatarUrl!,
                          fit: BoxFit.cover,
                          placeholder: (c, u) => _initialsWidget(initial),
                          errorWidget: (c, u, e) => _initialsWidget(initial),
                        )
                      : _initialsWidget(initial),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: isActive
                    ? Row(
                        children: [
                          const SizedBox(width: 6),
                          Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initialsWidget(String initial) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
