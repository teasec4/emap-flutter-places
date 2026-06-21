import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:emap_hangzhou/core/router/app_router.dart';
import 'package:emap_hangzhou/core/services/isar_service.dart';
import 'package:emap_hangzhou/features/favorites/presentation/viewmodels/favorites_viewmodel.dart';
import 'package:emap_hangzhou/features/map/data/repositories/place_repository_impl.dart';
import 'package:emap_hangzhou/features/map/domain/repositories/place_repository.dart';
import 'package:emap_hangzhou/features/map/presentation/viewmodels/map_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EmapSplashApp());
}

/// Minimal splash app shown while Isar initializes.
class EmapSplashApp extends StatelessWidget {
  const EmapSplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: _InitScreen());
  }
}

/// Handles Isar initialization and navigates to the real app.
class _InitScreen extends StatefulWidget {
  const _InitScreen();

  @override
  State<_InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<_InitScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await IsarService.init();
      if (!mounted) return;

      // Replace splash with real app
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const EmapApp()));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text('Failed to initialize'),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        setState(() => _error = null);
                        _initialize();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
      ),
    );
  }
}

/// The real app — only shown after Isar is ready.
class EmapApp extends StatelessWidget {
  const EmapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PlaceRepository>(create: (_) => PlaceRepositoryImpl()),
        ChangeNotifierProvider<MapViewModel>(
          create: (ctx) =>
              MapViewModel(repository: ctx.read<PlaceRepository>()),
        ),
        ChangeNotifierProvider<FavoritesViewModel>(
          create: (ctx) =>
              FavoritesViewModel(repository: ctx.read<PlaceRepository>()),
        ),
      ],
      child: MaterialApp.router(
        title: 'eMap Hangzhou',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
