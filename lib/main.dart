import 'package:flutter/material.dart';
import 'services/wallet.dart';
import 'services/billing_service.dart';
import 'screens/home_screen.dart';
import 'screens/store_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/themes_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Wallet.instance.load();
  BillingService.instance.init();
  runApp(const TevaApp());
}

const kThemeColors = <Color>[
  Color(0xFF00B894),
  Color(0xFF6C5CE7),
  Color(0xFFE17055),
  Color(0xFF0984E3),
  Color(0xFFE84393),
];

class TevaApp extends StatelessWidget {
  const TevaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Wallet.instance,
      builder: (context, _) => MaterialApp(
        title: 'Teva',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: kThemeColors[Wallet.instance.themeIndex],
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        ),
        home: const Shell(),
      ),
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
    const titles = ['Stats', 'Themes', 'Home', 'Store', 'Profile'];
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
            builder: (_, __) => Row(children: [
              _chip(Icons.workspace_premium, Colors.amber, Wallet.instance.badges),
              const SizedBox(width: 8),
              _chip(Icons.diamond, Colors.blue, Wallet.instance.diamonds),
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
          NavigationDestination(icon: Icon(Icons.palette), label: 'Themes'),
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.shopping_bag), label: 'Store'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, Color c, int v) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Row(children: [
          Icon(icon, color: c, size: 20),
          const SizedBox(width: 6),
          Text('$v', style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
      );
}
