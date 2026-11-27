import 'package:flutter/material.dart';
import '../services/wallet.dart';
import '../services/planes.dart';
import '../services/theme_controller.dart';

/// Your own stats. All numbers come from this phone.
/// (Online leaderboard can be added later with a server.)
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Wallet.instance,
      builder: (context, _) {
        final w = Wallet.instance;
        final c = Theme.of(context).colorScheme;

        int cleared = 0;
        int stars = 0;
        for (int i = 1; i <= kLevelCount; i++) {
          if (w.levelStars[i] > 0) cleared++;
          stars += w.levelStars[i];
        }

        Widget tile(IconData icon, String label, String value, Color color) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                Text(value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: c.primary)),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            Row(
              children: const [
                Icon(Icons.emoji_events, size: 22),
                SizedBox(width: 8),
                Text('My Stats',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                children: [
                  Text('HIGH SCORE',
                      style: TextStyle(
                          color: c.onPrimary.withOpacity(0.85),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 6),
                  Text('${w.highScore}',
                      style: TextStyle(
                          color: c.onPrimary,
                          fontSize: 44,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            tile(Icons.sports_esports, 'Games played', '${w.gamesPlayed}',
                const Color(0xFF6C5CE7)),
            const SizedBox(height: 10),
            tile(Icons.flag, 'Levels cleared', '$cleared / $kLevelCount',
                const Color(0xFF0984E3)),
            const SizedBox(height: 10),
            tile(Icons.star, 'Stars collected', '$stars / ${kLevelCount * 3}',
                const Color(0xFFFDCB6E)),
            const SizedBox(height: 10),
            tile(Icons.flight, 'Planes owned',
                '${w.ownedPlanes.length} / ${kPlanes.length}',
                const Color(0xFF00B894)),
            const SizedBox(height: 10),
            tile(Icons.local_fire_department, 'Daily streak',
                '${w.streak} / 7', const Color(0xFFE17055)),
            const SizedBox(height: 14),
            Text('Online ranking is coming in a future update.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, color: c.onSurface.withOpacity(0.6))),
          ],
        );
      },
    );
  }
}
