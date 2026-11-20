import 'package:flutter/material.dart';
import '../services/billing_service.dart';
import '../services/theme_controller.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final b = BillingService.instance;
    return ListenableBuilder(
      listenable: b,
      builder: (context, _) {
        final c = Theme.of(context).colorScheme;
        final ids = kDiamondPackages.keys.toList();
        return Column(
          children: [
            if (b.message != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(b.message!, style: TextStyle(color: c.primary)),
              ),
            if (b.loading) const LinearProgressIndicator(),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.95,
                ),
                itemCount: ids.length,
                itemBuilder: (_, i) {
                  final id = ids[i];
                  final amount = kDiamondPackages[id]!;
                  final p = b.products[id];
                  return Container(
                    decoration: BoxDecoration(
                      color: cardColor(context),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.diamond, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text('$amount',
                                style: const TextStyle(
                                    fontSize: 36, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: p == null ? null : () => b.buy(id),
                            child: Text(p?.price ?? 'Unavailable'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
