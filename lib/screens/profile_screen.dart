import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.premiumBadge ? 'Player  \u2713 Premium' : 'Player',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text('UID: ${w.uid}',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: w.uid));
                            _snack(context, 'UID copied');
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.copy, size: 18),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            _tile(context, Icons.badge, 'Change UID',
                'Get a new UID by reinstalling the app', () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Change your UID'),
                  content: const Text(
                      'Your UID is created when the app is first opened on '
                      'this phone. To get a new UID, uninstall the app and '
                      'install it again from Google Play.\n\n'
                      'Note: diamonds, planes and level progress on this '
                      'phone will be reset too.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('OK')),
                  ],
                ),
              );
            }),
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
