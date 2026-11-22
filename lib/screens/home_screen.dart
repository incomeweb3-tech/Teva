import 'package:flutter/material.dart';
import '../services/wallet.dart';
import '../services/planes.dart';
import 'levels_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: Wallet.instance,
      builder: (context, _) {
        final idx = Wallet.instance.selectedPlane;
        final plane = kPlanes[idx < kPlanes.length ? idx : 0];
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlaneIcon(color: plane.color, size: 96),
              const SizedBox(height: 8),
              const Text('Sky Combat',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Shoot down enemy planes \u2022 20 levels'),
              const SizedBox(height: 32),
              SizedBox(
                width: 180,
                height: 180,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      shape: const CircleBorder(), backgroundColor: c.primary),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LevelsScreen())),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 80),
                      Text('PLAY',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
