import 'package:go_router/go_router.dart';

import 'package:emap_hangzhou/features/map/presentation/screens/map_screen.dart';
import 'package:emap_hangzhou/features/map/presentation/screens/splash_screen.dart';
import 'package:emap_hangzhou/features/map/presentation/viewmodels/map_viewmodel.dart';

class AppRouter {
  AppRouter._();

  static GoRouter create(MapViewModel vm) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: vm,
      routes: [
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/map',
          name: 'map',
          builder: (context, state) => const MapScreen(),
        ),
      ],
      redirect: (context, state) {
        final location = state.uri.path;

        if (location == '/splash' && vm.isReady) return '/map';
        if (location == '/map' && !vm.isReady) return '/splash';
        return null;
      },
    );
  }
}
