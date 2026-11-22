import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'planes.dart';

/// Number of levels in the game.
const int kLevelCount = 20;

/// Holds diamonds, badges and stats.
///
/// NOTE: this stores data on the phone (SharedPreferences) so the app works
/// out of the box. Before real launch, move diamonds to a server (Firebase)
/// and verify purchase tokens there, otherwise users can tamper with it.
class Wallet extends ChangeNotifier {
  Wallet._();
  static final Wallet instance = Wallet._();

  late SharedPreferences _p;

  int diamonds = 0;
  int badges = 0;
  int highScore = 0;
  int gamesPlayed = 0;
  int themeIndex = 0;
  int streak = 0;
  bool premiumBadge = false;
  String lastDaily = '';
  List<String> history = [];

  /// Random player id. It is created on first launch and is stored on the
  /// phone only, so uninstalling and reinstalling the app gives a new one.
  String uid = '';
  int unlockedLevel = 1;
  List<int> levelStars = List.filled(kLevelCount + 1, 0); // index 1..20
  Set<int> ownedPlanes = {0};
  int selectedPlane = 0;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    diamonds = _p.getInt('diamonds') ?? 0;
    badges = _p.getInt('badges') ?? 0;
    highScore = _p.getInt('highScore') ?? 0;
    gamesPlayed = _p.getInt('gamesPlayed') ?? 0;
    themeIndex = _p.getInt('themeIndex') ?? 0;
    streak = _p.getInt('streak') ?? 0;
    premiumBadge = _p.getBool('premiumBadge') ?? false;
    lastDaily = _p.getString('lastDaily') ?? '';
    history = _p.getStringList('history') ?? [];

    uid = _p.getString('uid') ?? '';
    if (uid.isEmpty) {
      final r = Random.secure();
      uid = '${1 + r.nextInt(9)}${List.generate(7, (_) => r.nextInt(10)).join()}';
      _p.setString('uid', uid);
    }
    unlockedLevel =
        (_p.getInt('unlockedLevel') ?? 1).clamp(1, kLevelCount).toInt();
    levelStars = List.filled(kLevelCount + 1, 0);
    final st = (_p.getString('levelStars') ?? '').split(',');
    for (int i = 0; i < st.length && i < levelStars.length; i++) {
      levelStars[i] = int.tryParse(st[i]) ?? 0;
    }
    final owned = _p.getStringList('ownedPlanes');
    ownedPlanes = owned == null
        ? {0}
        : owned.map((e) => int.tryParse(e) ?? 0).toSet();
    ownedPlanes.add(0);
    selectedPlane = _p.getInt('selectedPlane') ?? 0;
    if (!ownedPlanes.contains(selectedPlane)) selectedPlane = 0;
  }

  void _save() {
    _p.setInt('diamonds', diamonds);
    _p.setInt('badges', badges);
    _p.setInt('highScore', highScore);
    _p.setInt('gamesPlayed', gamesPlayed);
    _p.setInt('themeIndex', themeIndex);
    _p.setInt('streak', streak);
    _p.setBool('premiumBadge', premiumBadge);
    _p.setString('lastDaily', lastDaily);
    _p.setStringList('history', history);
    _p.setInt('unlockedLevel', unlockedLevel);
    _p.setString('levelStars', levelStars.join(','));
    _p.setStringList('ownedPlanes', ownedPlanes.map((e) => '$e').toList());
    _p.setInt('selectedPlane', selectedPlane);
    notifyListeners();
  }

  void addDiamonds(int n) {
    diamonds += n;
    _save();
  }

  bool spend(int n) {
    if (diamonds < n) return false;
    diamonds -= n;
    _save();
    return true;
  }

  void buyBadge() {
    if (spend(100)) {
      badges += 1;
      _save();
    }
  }

  void buyPremiumBadge() {
    if (!premiumBadge && spend(999)) {
      premiumBadge = true;
      _save();
    }
  }

  /// Called once when a level ends (won or lost).
  void finishLevel({
    required int level,
    required int score,
    required int reward,
    required bool won,
    required int stars,
  }) {
    gamesPlayed += 1;
    if (score > highScore) highScore = score;
    diamonds += reward;
    if (won) {
      if (stars > levelStars[level]) levelStars[level] = stars;
      if (level >= unlockedLevel && level < kLevelCount) {
        unlockedLevel = level + 1;
      }
    }
    _save();
  }

  /// Buys a plane with diamonds and selects it. Returns false if it fails.
  bool buyPlane(int id) {
    if (id < 0 || id >= kPlanes.length) return false;
    if (ownedPlanes.contains(id)) return false;
    if (!spend(kPlanes[id].price)) return false;
    ownedPlanes.add(id);
    selectedPlane = id;
    _save();
    return true;
  }

  void selectPlane(int id) {
    if (!ownedPlanes.contains(id)) return;
    selectedPlane = id;
    _save();
  }

  void setTheme(int i) {
    themeIndex = i;
    _save();
  }

  void addHistory(String line) {
    history.insert(0, line);
    _save();
  }

  bool get canClaimDaily => lastDaily != _today();

  /// Returns diamonds given (0 if already claimed today).
  int claimDaily() {
    if (!canClaimDaily) return 0;
    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
    streak = (lastDaily == yesterday) ? streak + 1 : 1;
    if (streak > 7) streak = 1;
    lastDaily = _today();
    final reward = 5 * streak;
    diamonds += reward;
    _save();
    return reward;
  }

  String _today() => _dateKey(DateTime.now());
  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
