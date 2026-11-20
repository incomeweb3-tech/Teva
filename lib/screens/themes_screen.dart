import 'package:flutter/material.dart';
import '../main.dart' show kThemeColors;
import '../services/wallet.dart';

class ThemesScreen extends StatelessWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Wallet.instance,
      builder: (context, _) => GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          for (int i = 0; i < kThemeColors.length; i++)
            GestureDetector(
              onTap: () => Wallet.instance.setTheme(i),
              child: Container(
                decoration: BoxDecoration(
                  color: kThemeColors[i],
                  borderRadius: BorderRadius.circular(24),
                  border: Wallet.instance.themeIndex == i
                      ? Border.all(color: Colors.black, width: 3)
                      : null,
                ),
                child: Wallet.instance.themeIndex == i
                    ? const Icon(Icons.check, color: Colors.white, size: 36)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
