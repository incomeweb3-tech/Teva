import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void finishGame(int score, int reward) {
    gamesPlayed += 1;
    if (score > highScore) highScore = score;
    diamonds += reward;
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
