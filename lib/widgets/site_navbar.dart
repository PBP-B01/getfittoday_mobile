import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

enum NavDestination { home, community, store, booking, blogs }

class SiteNavBar extends StatelessWidget {
  static const List<_NavDefinition> _navItems = [
    _NavDefinition('Home', NavDestination.home),
    _NavDefinition('Community', NavDestination.community),
    _NavDefinition('Store', NavDestination.store),
    _NavDefinition('Booking', NavDestination.booking),
    _NavDefinition('Blogs & Events', NavDestination.blogs),
  ];

  final NavDestination active;
  final String brandTitle;

  const SiteNavBar({
    super.key,
    this.active = NavDestination.home,
    this.brandTitle = 'GETFIT.TODAY',
  });

  String _usernameFromRequest(CookieRequest request) {
    final data = request.jsonData;
    if (data is Map && data['username'] is String) {
      return data['username'] as String;
    }
    final cookie = request.cookies['username'];
    if (cookie != null && cookie.value.isNotEmpty) {
      return cookie.value;
    }
    return 'User';
  }

  void _go(BuildContext context, String routeName) {
    if (ModalRoute.of(context)?.settings.name == routeName) return;
    Navigator.pushReplacementNamed(context, routeName);
  }

  void _soon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label akan segera hadir.'),
          backgroundColor: accentDarkColor,
        ),
      );
  }

  Widget _navItem(
    BuildContext context, {
    required String label,
    required NavDestination destination,
    VoidCallback? onTap,
  }) {
    final isActive = destination == active;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(isActive ? 1 : 0.85),
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  void _handleNavTap(
    BuildContext context, {
    required NavDestination destination,
    required String label,
    VoidCallback? closeMenu,
  }) {
    closeMenu?.call();
    final route = _routeForDestination(destination);
    if (route != null) {
      _go(context, route);
    } else {
      _soon(context, label);
    }
  }

  String? _routeForDestination(NavDestination destination) {
    switch (destination) {
      case NavDestination.home:
        return '/home';
      case NavDestination.booking:
        return '/booking';
      default:
        return null;
    }
  }

  IconData _iconForDestination(NavDestination destination) {
    switch (destination) {
      case NavDestination.home:
        return Icons.home_filled;
      case NavDestination.community:
        return Icons.groups;
      case NavDestination.store:
        return Icons.storefront;
      case NavDestination.booking:
        return Icons.event_available;
      case NavDestination.blogs:
        return Icons.article;
    }
  }

  Future<void> _handleProfileAction(
    BuildContext context,
    CookieRequest request,
    _ProfileMenuAction action,
  ) async {
    switch (action) {
      case _ProfileMenuAction.bookings:
        _go(context, '/booking');
        break;
      case _ProfileMenuAction.logout:
        try {
          await request.logout('$djangoBaseUrl/auth/logout/');
        } catch (_) {
          // ignore logout exception, still navigate
        }
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('You have been logged out.'),
              backgroundColor: accentDarkColor,
            ),
          );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        break;
    }
  }

  void _openMobileMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      barrierLabel: 'Navigation menu',
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final media = MediaQuery.of(dialogContext);
        final panelWidth =
            media.size.width < 420 ? media.size.width * 0.86 : 360.0;
        final panelHeight = media.size.height - 32;
        final closeMenu = () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        };

        return Align(
          alignment: Alignment.centerRight,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: panelWidth,
                height: panelHeight,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(60, 0, 0, 0),
                      blurRadius: 26,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Menu',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: primaryNavColor,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: closeMenu,
                          icon: const Icon(Icons.close, color: primaryNavColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final nav in _navItems)
                            ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              leading: Icon(
                                _iconForDestination(nav.destination),
                                color: nav.destination == active
                                    ? accentDarkColor
                                    : primaryNavColor,
                              ),
                              title: Text(
                                nav.label,
                                style: TextStyle(
                                  fontWeight: nav.destination == active
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: nav.destination == active
                                      ? primaryNavColor
                                      : inputTextColor,
                                ),
                              ),
                              trailing:
                                  _routeForDestination(nav.destination) == null
                                      ? const Text(
                                          'Soon',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: inkWeakColor,
                                          ),
                                        )
                                      : null,
                              onTap: () => _handleNavTap(
                                context,
                                destination: nav.destination,
                                label: nav.label,
                                closeMenu: closeMenu,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        );
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final username = _usernameFromRequest(request);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: primaryNavColor,
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(45, 0, 0, 0),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 720;
            return Row(
              children: [
                Text(
                  brandTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const Spacer(),
                if (!isCompact)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: WrapAlignment.end,
                    children: [
                      for (final nav in _navItems)
                        _navItem(
                          context,
                          label: nav.label,
                          destination: nav.destination,
                          onTap: () => _handleNavTap(
                            context,
                            destination: nav.destination,
                            label: nav.label,
                          ),
                        ),
                    ],
                  )
                else
                  IconButton(
                    onPressed: () => _openMobileMenu(context),
                    icon: const Icon(Icons.menu, color: Colors.white, size: 26),
                    tooltip: 'Menu',
                  ),
                const SizedBox(width: 16),
            PopupMenuButton<_ProfileMenuAction>(
              tooltip: 'Profile',
              offset: const Offset(0, 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (action) =>
                  _handleProfileAction(context, request, action),
              itemBuilder: (context) => [
                PopupMenuItem<_ProfileMenuAction>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Signed in as',
                        style: TextStyle(
                          fontSize: 12,
                          color: inkWeakColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: primaryNavColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<_ProfileMenuAction>(
                  value: _ProfileMenuAction.bookings,
                  child: Text(
                    'My bookings',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: primaryNavColor,
                    ),
                  ),
                ),
                const PopupMenuItem<_ProfileMenuAction>(
                  value: _ProfileMenuAction.logout,
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(60, 0, 0, 0),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  color: inputTextColor,
                  size: 22,
                ),
              ),
            ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavDefinition {
  final String label;
  final NavDestination destination;

  const _NavDefinition(this.label, this.destination);
}

enum _ProfileMenuAction { bookings, logout }
