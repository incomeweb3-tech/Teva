import 'package:flutter/material.dart';
import '../services/wallet.dart';
import '../services/theme_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _snack(BuildContext c, String m) =>
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final w = Wallet.instance;
    return ListenableBuilder(
      listenable: w,
      builder: (context, _) {
        final c = Theme.of(context).colorScheme;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: c.primaryContainer,
                  borderRadius: BorderRadius.circular(28)),
              child: Row(children: [
                const CircleAvatar(radius: 32, child: Icon(Icons.person, size: 36)),
                const SizedBox(width: 16),
                Text(w.premiumBadge ? 'Player  \u2713 Premium' : 'Player',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900)),
              ]),
            ),
            const SizedBox(height: 16),
            _tile(context, Icons.card_giftcard, 'Daily Rewards',
                w.canClaimDaily
                    ? 'Claim today\'s reward (7-day streak)'
                    : 'Come back tomorrow! Streak: ${w.streak}/7', () {
              final r = w.claimDaily();
              _snack(context, r > 0 ? '+$r diamonds!' : 'Already claimed today');
            }),
            _tile(context, Icons.group, 'Referrals', 'Coming soon', () {
              _snack(context, 'Referrals will be added soon');
            }),
            _tile(context, Icons.workspace_premium, 'Buy Badge',
                '100 Diamonds per badge', () {
              if (w.diamonds < 100) {
                _snack(context, 'Not enough diamonds');
              } else {
                w.buyBadge();
                _snack(context, 'Badge purchased!');
              }
            }),
            _tile(
                context,
                Icons.verified,
                'Premium Badge',
                w.premiumBadge
                    ? 'Unlocked (cosmetic only)'
                    : 'Unlock for 999 Diamonds (cosmetic only)', () {
              if (w.premiumBadge) return;
              if (w.diamonds < 999) {
                _snack(context, 'Not enough diamonds');
              } else {
                w.buyPremiumBadge();
                _snack(context, 'Premium badge unlocked!');
              }
            }),
            _tile(context, Icons.attach_money, 'Purchase History',
                'See all your purchase records', () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const _HistoryScreen()));
            }),
          ],
        );
      },
    );
  }

  Widget _tile(BuildContext context, IconData i, String t, String s,
          VoidCallback f) =>
      Card(
        elevation: 0,
        color: cardColor(context),
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ListTile(
          leading: Icon(i),
          title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(s),
          trailing: const Icon(Icons.arrow_forward),
          onTap: f,
        ),
      );
}

class _HistoryScreen extends StatelessWidget {
  const _HistoryScreen();
  @override
  Widget build(BuildContext context) {
    final h = Wallet.instance.history;
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase History')),
      body: h.isEmpty
          ? const Center(child: Text('No purchases yet'))
          : ListView(
              children: [for (final e in h) ListTile(title: Text(e))],
            ),
    );
  }
}
