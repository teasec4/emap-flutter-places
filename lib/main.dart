import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:emap_hangzhou/core/constants/app_constants.dart';
import 'package:emap_hangzhou/core/router/app_router.dart';
import 'package:emap_hangzhou/features/map/presentation/viewmodels/map_viewmodel.dart';

/// Shared theme — both the splash and the routed app use the same look.
ThemeData _appTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    );

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SplashApp());
}

class SplashApp extends StatelessWidget {
  const SplashApp({super.key});

  @override
  Widget build(BuildContext context) =>
      MaterialApp(theme: _appTheme(), home: const _SplashScreen());
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  final MapViewModel _vm = MapViewModel();
  String _status = 'Loading...';
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1. Fetch POIs.
    setState(() => _status = 'Loading places...');
    await _vm.loadPois();

    if (!mounted) return;
    if (_vm.error != null) {
      setState(() {
        _error = _vm.error;
        _status = 'Failed to load';
      });
      return;
    }

    // 2. Try to get user location (best-effort, never fails the splash).
    setState(() => _status = 'Finding your location...');
    _vm.initialPosition = await _tryGetUserLocation();

    if (!mounted) return;
    setState(() => _status = 'Ready!');
    await Future.delayed(AppConstants.splashReadyDelay);
    if (!mounted) return;

    _navigateToMap();
  }

  Future<LatLng?> _tryGetUserLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.whileInUse &&
          perm != LocationPermission.always) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  void _navigateToMap() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: _vm,
          child: MaterialApp.router(
            title: 'eMap Hangzhou',
            theme: _appTheme(),
            routerConfig: AppRouter.router,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _error != null ? Icons.cloud_off : Icons.map,
              size: 72,
              color: _error != null ? Colors.red : theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            if (_error == null) const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_status, style: theme.textTheme.bodyMedium),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodySmall,
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
