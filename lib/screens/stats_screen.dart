import 'package:flutter/material.dart';
import '../services/wallet.dart';
import '../services/theme_controller.dart';

class _Entry {
  final String name;
  final int score;
  final bool me;
  const _Entry(this.name, this.score, {this.me = false});
}

// Sample players. Replace with real online data when a server is added.
const _samples = <_Entry>[
  _Entry('Faruk', 168),
  _Entry('Rafi', 142),
  _Entry('Tania', 131),
  _Entry('Sakib', 120),
  _Entry('Mim', 112),
  _Entry('Nayeem', 105),
  _Entry('Jahid', 98),
  _Entry('Rima', 86),
];

const _avatarColors = <Color>[
  Color(0xFF6C5CE7),
  Color(0xFFE17055),
  Color(0xFF0984E3),
  Color(0xFFE84393),
  Color(0xFF00B894),
  Color(0xFFFDCB6E),
  Color(0xFF636E72),
];

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Wallet.instance,
      builder: (context, _) {
        final w = Wallet.instance;
        final c = Theme.of(context).colorScheme;

        final all = <_Entry>[..._samples, _Entry('You', w.highScore, me: true)];
        all.sort((a, b) {
          final d = b.score - a.score;
          if (d != 0) return d;
          if (a.me) return 1;
          if (b.me) return -1;
          return 0;
        });
        final myRank = all.indexWhere((e) => e.me) + 1;

        Color avatarColor(_Entry e) => e.me
            ? c.primary
            : _avatarColors[e.name.codeUnitAt(0) % _avatarColors.length];

        Widget avatar(_Entry e, double size) => Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: avatarColor(e), shape: BoxShape.circle),
              child: Text(
                e.name.substring(0, 1),
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.4),
              ),
            );

        Widget pod(_Entry e, String medal, double h, bool first) => Expanded(
              child: Container(
                height: h,
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
                decoration: BoxDecoration(
                  color: first ? c.primaryContainer : cardColor(context),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  border: first ? Border.all(color: c.primary, width: 2) : null,
                ),
                child: Column(
                  children: [
                    Text(medal, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 4),
                    avatar(e, 52),
                    const SizedBox(height: 6),
                    Text(e.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('${e.score}',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: c.primary)),
                  ],
                ),
              ),
            );

        Widget row(int rank, _Entry e) => Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: e.me ? c.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text('$rank',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                  avatar(e, 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(e.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  Text('${e.score}',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: c.primary)),
                ],
              ),
            );

        final rest = all.skip(3).toList();

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, size: 22),
                      const SizedBox(width: 8),
                      const Text('Leaderboard',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Sample players. Online ranking coming soon.',
                      style: TextStyle(
                          fontSize: 12,
                          color: c.onSurface.withOpacity(0.6))),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      pod(all[1], '\u{1F948}', 165, false),
                      const SizedBox(width: 10),
                      pod(all[0], '\u{1F947}', 195, true),
                      const SizedBox(width: 10),
                      pod(all[2], '\u{1F949}', 150, false),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cardColor(context),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < rest.length; i++)
                          row(i + 4, rest[i]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Text('#$myRank',
                      style: TextStyle(
                          color: c.onPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('You',
                        style: TextStyle(
                            color: c.onPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ),
                  Text('High score ${w.highScore}',
                      style: TextStyle(
                          color: c.onPrimary, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
