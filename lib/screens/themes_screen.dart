import 'package:flutter/material.dart';
import '../services/theme_controller.dart';
import '../services/wallet.dart';
import '../services/planes.dart';

class ThemesScreen extends StatelessWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeController.instance, Wallet.instance]),
      builder: (context, _) {
        final t = ThemeController.instance;
        final w = Wallet.instance;
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
            const SizedBox(height: 16),
            _planeStore(context, w),
          ],
        );
      },
    );
  }

  Widget _planeStore(BuildContext context, Wallet w) {
    final c = Theme.of(context).colorScheme;
    return Container(
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
                child: Text('Plane Store',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              Text('\u{1F48E} ${w.diamonds}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Each plane has a super power.',
              style: TextStyle(color: c.onSurface.withOpacity(0.65))),
          const SizedBox(height: 12),
          for (final p in kPlanes) _planeRow(context, w, p),
        ],
      ),
    );
  }

  Widget _planeRow(BuildContext context, Wallet w, PlaneDef p) {
    final c = Theme.of(context).colorScheme;
    final owned = w.ownedPlanes.contains(p.id);
    final selected = w.selectedPlane == p.id;

    Widget action;
    if (selected) {
      action = FilledButton.tonal(
        onPressed: null,
        child: const Text('Selected'),
      );
    } else if (owned) {
      action = OutlinedButton(
        onPressed: () => w.selectPlane(p.id),
        child: const Text('Select'),
      );
    } else {
      action = FilledButton(
        onPressed: () => _buy(context, p),
        child: Text('\u{1F48E} ${p.price}'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: p.color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
              border: selected ? Border.all(color: c.primary, width: 2) : null,
            ),
            alignment: Alignment.center,
            child: PlaneIcon(color: p.color, size: 48),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(p.power,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: c.onSurface.withOpacity(0.7))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 98, height: 40, child: action),
        ],
      ),
    );
  }

  Future<void> _buy(BuildContext context, PlaneDef p) async {
    final w = Wallet.instance;
    final messenger = ScaffoldMessenger.of(context);
    if (w.diamonds < p.price) {
      messenger.showSnackBar(SnackBar(
          content: Text(
              'Not enough diamonds (need ${p.price - w.diamonds} more)')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Buy ${p.name}?'),
        content: Text('${p.price} diamonds\n${p.power}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Buy')),
        ],
      ),
    );
    if (ok == true && w.buyPlane(p.id)) {
      messenger.showSnackBar(
          SnackBar(content: Text('${p.name} unlocked and selected!')));
    }
  }
}
