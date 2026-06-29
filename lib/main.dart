import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:emap_hangzhou/core/router/app_router.dart';
import 'package:emap_hangzhou/features/map/presentation/viewmodels/map_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final mapViewModel = MapViewModel()..init();
  final router = AppRouter.create(mapViewModel);

  runApp(
    ChangeNotifierProvider.value(
      value: mapViewModel,
      child: EmapApp(router: router),
    ),
  );
}

class EmapApp extends StatelessWidget {
  const EmapApp({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'eMap Hangzhou',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
