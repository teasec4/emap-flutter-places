import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:emap_hangzhou/features/map/presentation/screens/map_screen.dart';
import 'package:emap_hangzhou/features/favorites/presentation/screens/favorites_screen.dart';

/// Central route configuration.
///
/// Uses a [ShellRoute] so the BottomNavigationBar persists across tab switches.
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/map',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/map',
            name: 'map',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MapScreen()),
          ),
          GoRoute(
            path: '/favorites',
            name: 'favorites',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FavoritesScreen()),
          ),
        ],
      ),
    ],
  );
}

/// Wraps the child with a persistent [BottomNavigationBar].
class _ShellScreen extends StatelessWidget {
  const _ShellScreen({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateIndex(context),
        onTap: (index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }

  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/favorites')) return 1;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.goNamed('map');
        break;
      case 1:
        context.goNamed('favorites');
        break;
    }
  }
}
