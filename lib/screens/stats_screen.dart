import 'package:flutter/material.dart';
import '../services/wallet.dart';
import '../services/theme_controller.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Wallet.instance,
      builder: (context, _) {
        final w = Wallet.instance;
        Widget row(String a, String b) => Card(
              elevation: 0,
              color: cardColor(context),
              child: ListTile(
                title: Text(a),
                trailing: Text(b,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            );
        return ListView(padding: const EdgeInsets.all(16), children: [
          row('High score', '${w.highScore}'),
          row('Games played', '${w.gamesPlayed}'),
          row('Diamonds', '${w.diamonds}'),
          row('Badges', '${w.badges}'),
        ]);
      },
    );
  }
}
