import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The 4 accent colors shown as dots in the Theme screen.
const kThemeColors = <Color>[
  Color(0xFF00B894), // green
  Color(0xFF6C5CE7), // purple
  Color(0xFFE17055), // orange
  Color(0xFF0984E3), // blue
];

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  int colorIndex = 0;
  bool dark = false;

  Color get seed => kThemeColors[colorIndex];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    colorIndex = p.getInt('tc_color') ?? 0;
    if (colorIndex < 0 || colorIndex >= kThemeColors.length) colorIndex = 0;
    dark = p.getBool('tc_dark') ?? false;
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('tc_color', colorIndex);
    await p.setBool('tc_dark', dark);
  }

  void setColor(int i) {
    colorIndex = i;
    notifyListeners();
    _save();
  }

  void setDark(bool v) {
    dark = v;
    notifyListeners();
    _save();
  }

  void reset() {
    colorIndex = 0;
    dark = false;
    notifyListeners();
    _save();
  }
}

/// Card background that works in both light and dark mode.
Color cardColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1F2430)
        : Colors.white;
