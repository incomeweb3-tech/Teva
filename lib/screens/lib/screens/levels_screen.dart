import 'package:flutter/material.dart';
import '../services/wallet.dart';
import '../services/theme_controller.dart';
import 'game_screen.dart';

/// Level select: levels 1-20. A level opens after you clear the one before it.
class LevelsScreen extends StatelessWidget {
  const LevelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Level')),
      body: ListenableBuilder(
        listenable: Wallet.instance,
        builder: (context, _) {
          final w = Wallet.instance;
          final c = Theme.of(context).colorScheme;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Easy 1-5  \u2022  Normal 6-10  \u2022  Hard 11-15  \u2022  Insane 16-20',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12.5, color: c.onSurface.withOpacity(0.65)),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: kLevelCount,
                  itemBuilder: (context, i) {
                    final level = i + 1;
                    final open = level <= w.unlockedLevel;
                    final stars = w.levelStars[level];
                    final boss = level % 5 == 0;
                    return GestureDetector(
                      onTap: () {
                        if (!open) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                                  Text('Clear level ${level - 1} first')));
                          return;
                        }
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => GameScreen(level: level)));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: open ? c.primary : cardColor(context),
                          borderRadius: BorderRadius.circular(20),
                          border: boss
                              ? Border.all(color: Colors.redAccent, width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (open)
                              Text('$level',
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: c.onPrimary))
                            else
                              Icon(Icons.lock,
                                  size: 26,
                                  color: c.onSurface.withOpacity(0.4)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (int s = 1; s <= 3; s++)
                                  Icon(
                                    s <= stars ? Icons.star : Icons.star_border,
                                    size: 14,
                                    color: open
                                        ? Colors.amber
                                        : c.onSurface.withOpacity(0.25),
                                  ),
                              ],
                            ),
                            if (boss)
                              Text('BOSS',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: open
                                          ? c.onPrimary
                                          : Colors.redAccent)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
