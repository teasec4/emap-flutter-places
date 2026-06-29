import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:emap_hangzhou/features/map/presentation/viewmodels/map_viewmodel.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MapViewModel>();
    final hasError = vm.error != null;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasError ? Icons.cloud_off : Icons.map,
              size: 72,
              color: hasError ? Colors.red : Colors.blue,
            ),
            const SizedBox(height: 24),
            if (!hasError) const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(hasError ? 'Failed to load' : 'Loading...'),
            if (hasError) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  vm.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: vm.isLoading ? null : vm.init,
                child: Text(vm.isLoading ? 'Retrying...' : 'Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
