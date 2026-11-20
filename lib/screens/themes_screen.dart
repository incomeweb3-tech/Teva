import 'package:flutter/material.dart';
import '../services/theme_controller.dart';

class ThemesScreen extends StatelessWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final t = ThemeController.instance;
        final c = Theme.of(context).colorScheme;
        final trackColor =
            t.dark ? const Color(0xFF2A2F3A) : const Color(0xFFF5F5F5);

        Widget modeButton(String label, IconData icon, bool selected,
            VoidCallback onTap) {
          return Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: selected ? c.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: selected ? c.onPrimary : c.primary),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: selected ? c.onPrimary : c.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor(context),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Display Mode',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ),
                      // 4 small color dots: tap to change the whole app color
                      for (int i = 0; i < kThemeColors.length; i++)
                        GestureDetector(
                          onTap: () => t.setColor(i),
                          child: Container(
                            width: 30,
                            height: 30,
                            margin: const EdgeInsets.only(left: 10),
                            decoration: BoxDecoration(
                              color: kThemeColors[i],
                              shape: BoxShape.circle,
                              border: t.colorIndex == i
                                  ? Border.all(color: c.onSurface, width: 3)
                                  : null,
                            ),
                            child: t.colorIndex == i
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        modeButton('Light', Icons.palette, !t.dark,
                            () => t.setDark(false)),
                        modeButton('Dark', Icons.nightlight_round, t.dark,
                            () => t.setDark(true)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () => t.reset(),
                      child: const Text('Reset Theme',
                          style: TextStyle(fontSize: 17)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
