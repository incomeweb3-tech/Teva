import 'package:flutter/material.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Tap Rush',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Tap the targets for 30 seconds'),
          const SizedBox(height: 32),
          SizedBox(
            width: 180,
            height: 180,
            child: FilledButton(
              style: FilledButton.styleFrom(
                  shape: const CircleBorder(), backgroundColor: c.primary),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const GameScreen())),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 80),
                  Text('PLAY',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
