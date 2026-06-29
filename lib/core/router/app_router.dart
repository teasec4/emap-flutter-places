import 'package:go_router/go_router.dart';

import 'package:emap_hangzhou/features/map/presentation/screens/map_screen.dart';

/// Central route configuration.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'map',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: MapScreen()),
      ),
    ],
  );
}
