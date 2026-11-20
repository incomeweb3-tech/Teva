import 'package:flutter/material.dart';
import 'services/wallet.dart';
import 'services/billing_service.dart';
import 'services/theme_controller.dart';
import 'screens/home_screen.dart';
import 'screens/store_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/themes_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Wallet.instance.load();
  await ThemeController.instance.load();
  BillingService.instance.init();
  runApp(const TevaApp());
}

class TevaApp extends StatelessWidget {
  const TevaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final t = ThemeController.instance;
        return MaterialApp(
          title: 'Teva',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: t.dark ? Brightness.dark : Brightness.light,
            colorSchemeSeed: t.seed,
            scaffoldBackgroundColor:
                t.dark ? const Color(0xFF12151C) : const Color(0xFFF5F5F5),
          ),
          home: const Shell(),
        );
      },
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 2; // Home

  @override
  Widget build(BuildContext context) {
    const titles = ['Stats', 'Theme', 'Home', 'Store', 'Profile'];
    final pages = const [
      StatsScreen(),
      ThemesScreen(),
      HomeScreen(),
      StoreScreen(),
      ProfileScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(titles[_i],
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28)),
        actions: [
          ListenableBuilder(
            listenable: Wallet.instance,
            builder: (ctx, __) => Row(children: [
              _chip(ctx, Icons.workspace_premium, Colors.amber,
                  Wallet.instance.badges),
              const SizedBox(width: 8),
              _chip(ctx, Icons.diamond, Colors.blue, Wallet.instance.diamonds),
              const SizedBox(width: 12),
            ]),
          ),
        ],
      ),
      body: pages[_i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.palette), label: 'Theme'),
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.shopping_bag), label: 'Store'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, Color c, int v) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: cardColor(context), borderRadius: BorderRadius.circular(24)),
        child: Row(children: [
          Icon(icon, color: c, size: 20),
          const SizedBox(width: 6),
          Text('$v',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
        ]),
      );
}
