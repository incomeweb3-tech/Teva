import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/wallet.dart';

/// Tap Rush: tap targets for 30 seconds.
/// Reward: 1 diamond per 5 points, max 20 per game (anti-abuse cap).
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int _seconds = 30;
  final _rng = Random();
  Timer? _tick;
  Timer? _spawn;
  int _left = _seconds;
  int _score = 0;
  bool _over = false;
  int _reward = 0;
  Offset _target = const Offset(0.5, 0.5);
  Size _area = Size.zero;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_left <= 1) {
        _end();
      } else {
        setState(() => _left--);
      }
    });
    _spawn = Timer.periodic(const Duration(milliseconds: 800), (_) => _move());
  }

  void _move() {
    if (_over) return;
    setState(() =>
        _target = Offset(_rng.nextDouble(), _rng.nextDouble()));
  }

  void _hit() {
    if (_over) return;
    setState(() => _score++);
    _move();
  }

  void _end() {
    _tick?.cancel();
    _spawn?.cancel();
    _reward = min(20, _score ~/ 5);
    Wallet.instance.finishGame(_score, _reward);
    setState(() {
      _left = 0;
      _over = true;
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _spawn?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('Time: $_left   Score: $_score')),
      body: _over
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Game Over',
                      style: TextStyle(
                          fontSize: 32, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Text('Score: $_score', style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 8),
                  Text('+$_reward diamonds',
                      style: const TextStyle(fontSize: 20, color: Colors.blue)),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GameScreen())),
                    child: const Text('Play again'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Home'),
                  ),
                ],
              ),
            )
          : LayoutBuilder(builder: (context, box) {
              _area = Size(box.maxWidth, box.maxHeight);
              const r = 36.0;
              final x = _target.dx * (_area.width - 2 * r);
              final y = _target.dy * (_area.height - 2 * r);
              return Stack(children: [
                Positioned(
                  left: x,
                  top: y,
                  child: GestureDetector(
                    onTapDown: (_) => _hit(),
                    child: Container(
                      width: 2 * r,
                      height: 2 * r,
                      decoration:
                          BoxDecoration(color: c.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.touch_app, color: Colors.white),
                    ),
                  ),
                ),
              ]);
            }),
    );
  }
}
