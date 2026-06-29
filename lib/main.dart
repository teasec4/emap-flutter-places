import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:emap_hangzhou/core/router/app_router.dart';
import 'package:emap_hangzhou/features/map/presentation/viewmodels/map_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SplashApp());
}

class SplashApp extends StatelessWidget {
  const SplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const _SplashScreen(),
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  final _vm = MapViewModel();
  String _status = 'Loading...';
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1. Fetch POIs from server
    setState(() => _status = 'Loading places...');
    await _vm.loadPois();

    if (_vm.error != null) {
      setState(() {
        _error = _vm.error;
        _status = 'Failed to load';
      });
      return;
    }

    // 2. Try to get user location
    setState(() => _status = 'Finding your location...');
    LatLng? userPos;
    try {
      final ok = await Geolocator.isLocationServiceEnabled();
      if (ok) {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.whileInUse ||
            perm == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 5),
            ),
          );
          userPos = LatLng(pos.latitude, pos.longitude);
        }
      }
    } catch (_) {}

    setState(() => _status = 'Ready!');
    _vm.setInitialPosition(userPos);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    _navigateToMap();
  }

  void _navigateToMap() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: _vm,
          child: MaterialApp.router(
            title: 'eMap Hangzhou',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            routerConfig: AppRouter.router,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _error != null ? Icons.cloud_off : Icons.map,
              size: 72,
              color: _error != null
                  ? Colors.red
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            if (_error == null) const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_status, style: Theme.of(context).textTheme.bodyMedium),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _status = 'Retrying...';
                  });
                  _init();
                },
                child: const Text('Retry'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _navigateToMap,
                child: const Text('Skip — open map anyway'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension on MapViewModel {
  void setInitialPosition(LatLng? pos) {
    initialPosition = pos;
  }
}
