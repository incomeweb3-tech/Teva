import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/wallet.dart';
import '../services/theme_controller.dart';
import '../services/planes.dart';

/// Sky Combat: 2D air shooter with 20 levels.
/// Drag to fly (auto-fire), hold FIRE for rapid fire, missiles and shield.
/// Every level is a few waves; clear all waves to win and unlock the next
/// level. Higher levels have faster, tougher enemies that shoot more.
/// Reward per run is capped at 20 diamonds (anti-abuse).

const double kW = 400; // world width (height depends on screen)

enum _Kind { grunt, fast, heavy, boss }

class _Enemy {
  final _Kind kind;
  double x;
  double y;
  double hp;
  final double maxHp;
  final double r;
  final double speed;
  final double phase;
  double shootT;
  _Enemy(this.kind, this.x, this.y, this.hp, this.r, this.speed, this.phase,
      this.shootT)
      : maxHp = hp;
}

class _Bullet {
  double x;
  double y;
  double vx;
  double vy;
  final int dmg;
  _Bullet(this.x, this.y, this.vx, this.vy, this.dmg);
}

class _Missile {
  double x;
  double y;
  double vx;
  double vy;
  _Missile(this.x, this.y, this.vx, this.vy);
}

class _Fx {
  final double x;
  final double y;
  final double dur;
  final double size;
  final bool smoke;
  double t = 0;
  _Fx(this.x, this.y, this.dur, this.size, {this.smoke = false});
}

class _Pick {
  double x;
  double y;
  _Pick(this.x, this.y);
}

class _Cloud {
  final double x;
  final double y;
  final double scale;
  final double speed;
  _Cloud(this.x, this.y, this.scale, this.speed);
}

class _CombatGame extends ChangeNotifier {
  final int level;
  final PlaneDef plane;
  final int maxHp;
  final int maxMissiles;
  final int totalWaves;
  int revivesLeft;
  bool won = false;
  int stars = 0;

  final _rng = Random();
  double worldH = 800;
  bool ready = false;
  bool over = false;
  double t = 0;

  double px = 200;
  double py = 640;
  int hp;
  double invuln = 0;
  double shieldLeft = 0;
  int missiles;
  int shields = 2;
  bool firing = false;
  double fireT = 0;

  int wave = 1;
  int score = 0;
  int collected = 0;
  int reward = 0;
  double banner = 0;
  String bannerText = '';
  double spawnT = 0;
  double clearT = 0;
  bool _saved = false;

  final List<_Kind> queue = [];
  final List<_Enemy> enemies = [];
  final List<_Bullet> pBullets = [];
  final List<_Bullet> eBullets = [];
  final List<_Missile> missileList = [];
  final List<_Fx> fx = [];
  final List<_Pick> picks = [];
  final List<_Cloud> clouds = [];

  _CombatGame(this.level, this.plane)
      : maxHp = plane.maxHp,
        hp = plane.maxHp,
        missiles = plane.missiles,
        maxMissiles = plane.missiles + 2,
        revivesLeft = plane.revives,
        totalWaves = 3 + level ~/ 4 {
    for (int i = 0; i < 9; i++) {
      clouds.add(_Cloud(_rng.nextDouble() * kW, _rng.nextDouble() * 1000,
          0.7 + _rng.nextDouble() * 0.7, 30 + _rng.nextDouble() * 40));
    }
  }

  _Enemy? get boss {
    for (final e in enemies) {
      if (e.kind == _Kind.boss) return e;
    }
    return null;
  }

  void setSize(double w, double h) {
    worldH = kW * h / w;
    if (!ready) {
      ready = true;
      py = worldH * 0.8;
      _startWave();
    }
  }

  // ---- difficulty (grows with the level) ----
  double get _speedMul => 1 + 0.04 * (level - 1);
  double get _shootMul => max(0.5, 1 - 0.03 * (level - 1));
  double get _bulletMul => 1 + 0.02 * (level - 1);
  double get _gruntHp => (2 + level ~/ 8).toDouble();
  double get _fastHp => (1 + level ~/ 10).toDouble();
  double get _heavyHp => (5 + level ~/ 3).toDouble();

  bool get _bossLevel => level % 5 == 0;

  void _startWave() {
    queue.clear();
    final last = wave == totalWaves;
    if (last && _bossLevel) {
      queue.add(_Kind.boss);
      final n = 2 + level ~/ 5;
      for (int i = 0; i < n; i++) {
        queue.add(_Kind.grunt);
      }
    } else {
      final n = 3 + level ~/ 2 + wave;
      final heavyP = level >= 3 ? min(0.3, 0.05 + level * 0.015) : 0.0;
      for (int i = 0; i < n; i++) {
        final r = _rng.nextDouble();
        if (r < heavyP) {
          queue.add(_Kind.heavy);
        } else if (r < heavyP + 0.25) {
          queue.add(_Kind.fast);
        } else {
          queue.add(_Kind.grunt);
        }
      }
    }
    banner = 1.8;
    bannerText = last ? (_bossLevel ? 'BOSS WAVE' : 'FINAL WAVE') : 'WAVE $wave';
    spawnT = 1.8;
    clearT = 0;
  }

  void _spawn(_Kind kind) {
    final x = 40 + _rng.nextDouble() * (kW - 80);
    final ph = _rng.nextDouble() * 6;
    switch (kind) {
      case _Kind.grunt:
        enemies.add(_Enemy(kind, x, -40, _gruntHp, 26,
            (90 + wave * 4.0) * _speedMul, ph,
            (1.0 + _rng.nextDouble() * 2) * _shootMul));
        break;
      case _Kind.fast:
        enemies.add(_Enemy(kind, x, -40, _fastHp, 22,
            (150 + wave * 5.0) * _speedMul, ph, 99));
        break;
      case _Kind.heavy:
        enemies.add(_Enemy(kind, x, -50, _heavyHp, 34, 60 * _speedMul, ph,
            (1.5 + _rng.nextDouble() * 1.5) * _shootMul));
        break;
      case _Kind.boss:
        enemies.add(
            _Enemy(kind, kW / 2, -120, 40.0 + level * 6, 70, 70, ph, 2));
        break;
    }
  }

  void _waveCleared() {
    final w = wave;
    score += 200 * w;
    if (w >= totalWaves) {
      _finish(true);
      return;
    }
    hp = min(maxHp, hp + 15);
    if (w % 2 == 0) missiles = min(maxMissiles, missiles + 1);
    if (w % 3 == 0) shields = min(3, shields + 1);
    wave++;
    _startWave();
  }

  /// Ends the level once (win or lose) and saves progress.
  void _finish(bool win) {
    if (over) return;
    over = true;
    won = win;
    if (win) {
      score += 300 * level;
      final pct = hp / maxHp;
      stars = pct >= 0.7 ? 3 : (pct >= 0.4 ? 2 : 1);
      reward = min(20, collected + 5 + level ~/ 2);
    } else {
      reward = min(20, collected);
    }
    if (!_saved) {
      _saved = true;
      Wallet.instance.finishLevel(
          level: level, score: score, reward: reward, won: win, stars: stars);
    }
    notifyListeners();
  }

  // ---- controls ----
  void move(double dx, double dy) {
    if (over || !ready) return;
    px = (px + dx).clamp(30.0, kW - 30).toDouble();
    py = (py + dy).clamp(worldH * 0.3, worldH - 60).toDouble();
  }

  void setFiring(bool v) {
    firing = v;
  }

  void fireMissile() {
    if (over || !ready || missiles <= 0) return;
    missiles--;
    missileList.add(_Missile(px, py - 30, 0, -380));
    notifyListeners();
  }

  void useShield() {
    if (over || !ready || shields <= 0 || shieldLeft > 0) return;
    shields--;
    shieldLeft = 4;
    notifyListeners();
  }

  // ---- combat helpers ----
  void _hurt(int dmg) {
    if (over || invuln > 0 || shieldLeft > 0) return;
    hp -= dmg;
    invuln = 0.7;
    fx.add(_Fx(px, py, 0.3, 18));
    if (hp <= 0) {
      if (revivesLeft > 0) {
        revivesLeft--;
        hp = (maxHp * 0.5).round();
        invuln = 2.5;
        shieldLeft = 2;
        fx.add(_Fx(px, py, 0.8, 70));
        banner = 1.2;
        bannerText = 'REVIVED!';
      } else {
        hp = 0;
        _finish(false);
      }
    }
  }

  void _drop(_Enemy e, double prob, int n) {
    if (_rng.nextDouble() < prob) {
      for (int i = 0; i < n; i++) {
        picks.add(_Pick(e.x + i * 18 - (n - 1) * 9, e.y));
      }
    }
  }

  void _kill(_Enemy e) {
    enemies.remove(e);
    switch (e.kind) {
      case _Kind.grunt:
        score += 100;
        _drop(e, 0.3, 1);
        break;
      case _Kind.fast:
        score += 150;
        _drop(e, 0.2, 1);
        break;
      case _Kind.heavy:
        score += 300;
        _drop(e, 0.6, 2);
        break;
      case _Kind.boss:
        score += 2000;
        for (int i = 0; i < 5; i++) {
          picks.add(_Pick(e.x + (i - 2) * 28, e.y));
        }
        break;
    }
    fx.add(_Fx(e.x, e.y, 0.5, e.kind == _Kind.boss ? 70 : 30));
  }

  void _enemyShoot(_Enemy e) {
    switch (e.kind) {
      case _Kind.grunt:
        eBullets.add(_Bullet(e.x, e.y + 24, 0, 230 * _bulletMul, 8));
        e.shootT = (1.8 + _rng.nextDouble() * 1.4) * _shootMul;
        break;
      case _Kind.heavy:
        for (final a in [-0.25, 0.0, 0.25]) {
          eBullets.add(_Bullet(e.x, e.y + 30, sin(a) * 210 * _bulletMul,
              cos(a) * 210 * _bulletMul, 8));
        }
        e.shootT = (2.2 + _rng.nextDouble()) * _shootMul;
        break;
      case _Kind.boss:
        final spread = level >= 15 ? 3 : 2;
        for (int i = -spread; i <= spread; i++) {
          final a = i * 0.25;
          eBullets.add(_Bullet(e.x, e.y + 60, sin(a) * 220 * _bulletMul,
              cos(a) * 220 * _bulletMul, 10));
        }
        final dx = px - e.x;
        final dy = py - e.y;
        final d = max(1.0, sqrt(dx * dx + dy * dy));
        eBullets.add(_Bullet(e.x, e.y + 60, dx / d * 260 * _bulletMul,
            dy / d * 260 * _bulletMul, 10));
        e.shootT = max(0.8, 1.3 - level * 0.02);
        break;
      case _Kind.fast:
        break;
    }
  }

  void _explodeMissile(_Missile m, _Enemy hit) {
    hit.hp -= plane.missileDmg;
    for (final e in enemies) {
      if (e == hit) continue;
      final dx = e.x - m.x;
      final dy = e.y - m.y;
      if (sqrt(dx * dx + dy * dy) < 70) e.hp -= plane.missileDmg / 2;
    }
    fx.add(_Fx(m.x, m.y, 0.5, 40));
  }

  // ---- main update ----
  void update(double dt) {
    if (!ready || over) return;
    t += dt;
    if (invuln > 0) invuln = max(0.0, invuln - dt);
    if (shieldLeft > 0) shieldLeft = max(0.0, shieldLeft - dt);
    if (banner > 0) banner = max(0.0, banner - dt);

    // waves
    if (queue.isNotEmpty) {
      spawnT -= dt;
      if (spawnT <= 0) {
        _spawn(queue.removeAt(0));
        spawnT = 0.7;
      }
    } else if (enemies.isEmpty) {
      clearT += dt;
      if (clearT >= 1.0) _waveCleared();
    }

    // player fire
    fireT -= dt;
    if (fireT <= 0) {
      fireT = (firing ? 0.09 : 0.17) * plane.fireMul;
      if (plane.shots >= 3) {
        pBullets.add(_Bullet(px - 14, py - 28, -70, -630, 1));
        pBullets.add(_Bullet(px, py - 34, 0, -640, 1));
        pBullets.add(_Bullet(px + 14, py - 28, 70, -630, 1));
      } else {
        pBullets.add(_Bullet(px - 12, py - 30, 0, -640, 1));
        pBullets.add(_Bullet(px + 12, py - 30, 0, -640, 1));
      }
    }

    // bullets
    for (final b in pBullets) {
      b.x += b.vx * dt;
      b.y += b.vy * dt;
    }
    for (final b in eBullets) {
      b.x += b.vx * dt;
      b.y += b.vy * dt;
    }

    // enemies
    for (final e in enemies) {
      switch (e.kind) {
        case _Kind.grunt:
          e.y += e.speed * dt;
          e.x += sin(t * 1.5 + e.phase) * 40 * dt;
          break;
        case _Kind.fast:
          e.y += e.speed * dt;
          e.x += sin(t * 3 + e.phase) * 90 * dt;
          break;
        case _Kind.heavy:
          e.y += e.speed * dt;
          e.x += sin(t + e.phase) * 25 * dt;
          break;
        case _Kind.boss:
          if (e.y < 170) {
            e.y += 70 * dt;
          } else {
            e.x += cos(t * 0.8 + e.phase) * 88 * dt;
          }
          break;
      }
      e.x = e.x.clamp(20.0, kW - 20).toDouble();

      if (e.kind != _Kind.fast && e.y > 20 && e.y < worldH * 0.75) {
        e.shootT -= dt;
        if (e.shootT <= 0) _enemyShoot(e);
      }
    }
    enemies.removeWhere((e) => e.kind != _Kind.boss && e.y > worldH + 60);

    // player bullets hit enemies
    for (final b in pBullets) {
      for (final e in enemies) {
        if (e.hp <= 0) continue;
        if ((b.x - e.x).abs() < e.r && (b.y - e.y).abs() < e.r) {
          e.hp -= b.dmg;
          fx.add(_Fx(b.x, b.y, 0.15, 8));
          b.y = -999;
          break;
        }
      }
    }
    pBullets.removeWhere((b) => b.y < -30 || b.x < -30 || b.x > kW + 30);

    // enemy bullets hit player
    for (final b in eBullets) {
      if ((b.x - px).abs() < 18 && (b.y - py).abs() < 24) {
        _hurt(b.dmg);
        b.y = 9999;
      }
    }
    eBullets.removeWhere(
        (b) => b.y > worldH + 30 || b.y < -80 || b.x < -30 || b.x > kW + 30);

    // ramming
    for (final e in enemies) {
      if ((e.x - px).abs() < e.r + 14 && (e.y - py).abs() < e.r + 14) {
        if (invuln <= 0) {
          _hurt(20);
          if (e.kind != _Kind.boss) e.hp -= 5;
        }
      }
    }

    // missiles
    for (final m in missileList) {
      _Enemy? tgt;
      double best = 1e9;
      for (final e in enemies) {
        if (e.y < 0) continue;
        final d = (e.x - m.x) * (e.x - m.x) + (e.y - m.y) * (e.y - m.y);
        if (d < best) {
          best = d;
          tgt = e;
        }
      }
      if (tgt != null) {
        final dx = tgt.x - m.x;
        final dy = tgt.y - m.y;
        final d = max(1.0, sqrt(dx * dx + dy * dy));
        final k = min(1.0, 6 * dt);
        m.vx += (dx / d * 380 - m.vx) * k;
        m.vy += (dy / d * 380 - m.vy) * k;
      }
      m.x += m.vx * dt;
      m.y += m.vy * dt;
      fx.add(_Fx(m.x - m.vx * 0.02, m.y - m.vy * 0.02, 0.5, 7, smoke: true));
      for (final e in enemies) {
        if ((e.x - m.x).abs() < e.r + 8 && (e.y - m.y).abs() < e.r + 8) {
          _explodeMissile(m, e);
          m.y = -999;
          break;
        }
      }
    }
    missileList.removeWhere(
        (m) => m.y < -60 || m.y > worldH + 60 || m.x < -60 || m.x > kW + 60);

    // kills
    for (final e in enemies.where((e) => e.hp <= 0).toList()) {
      _kill(e);
    }

    // pickups
    for (final p in picks) {
      p.y += 110 * dt;
      if ((p.x - px).abs() < 34 && (p.y - py).abs() < 40) {
        collected++;
        p.y = 9999;
      }
    }
    picks.removeWhere((p) => p.y > worldH + 20);

    // effects
    for (final f in fx) {
      f.t += dt;
    }
    fx.removeWhere((f) => f.t >= f.dur);

    notifyListeners();
  }
}

class GameScreen extends StatefulWidget {
  final int level;
  const GameScreen({super.key, this.level = 1});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final _CombatGame g;
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    final idx = Wallet.instance.selectedPlane;
    g = _CombatGame(widget.level, kPlanes[idx < kPlanes.length ? idx : 0]);
    _ticker = createTicker((elapsed) {
      final dt =
          ((elapsed - _last).inMicroseconds / 1000000.0).clamp(0.0, 0.05);
      _last = elapsed;
      g.update(dt.toDouble());
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    g.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, box) {
        g.setSize(box.maxWidth, box.maxHeight);
        final s = kW / box.maxWidth;
        final c = Theme.of(context).colorScheme;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) => g.move(d.delta.dx * s, d.delta.dy * s),
                child: CustomPaint(painter: _CombatPainter(g)),
              ),
            ),
            Positioned.fill(
              child: ListenableBuilder(
                listenable: g,
                builder: (context, _) => _hud(context, c),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Colors.black)),
      );

  Widget _btn(Color color, double size, Widget child) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.85), width: 3),
        ),
        child: child,
      );

  Widget _hud(BuildContext context, ColorScheme c) {
    final boss = g.boss;
    final bigStyle = TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      shadows: [Shadow(blurRadius: 12, color: Colors.black.withOpacity(0.4))],
    );
    const whiteBold = TextStyle(
        color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12);

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _chip('Lv ${g.level}  W ${g.wave}/${g.totalWaves}'),
                      _chip('Score ${g.score}'),
                      _chip('\u{1F48E} ${g.collected}'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: g.hp / g.maxHp,
                            minHeight: 12,
                            backgroundColor: Colors.white.withOpacity(0.5),
                            color: g.hp > 30
                                ? const Color(0xFF00B894)
                                : Colors.redAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('${(g.hp * 100 / g.maxHp).round()}%',
                          style: whiteBold),
                    ],
                  ),
                  if (boss != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('BOSS', style: whiteBold),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: (boss.hp / boss.maxHp)
                                    .clamp(0.0, 1.0)
                                    .toDouble(),
                                minHeight: 10,
                                backgroundColor:
                                    Colors.white.withOpacity(0.5),
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // FIRE (hold for rapid fire)
        Positioned(
          right: 16,
          bottom: 28,
          child: SafeArea(
            child: Listener(
              onPointerDown: (_) => g.setFiring(true),
              onPointerUp: (_) => g.setFiring(false),
              onPointerCancel: (_) => g.setFiring(false),
              child: _btn(
                const Color(0xFFD63031),
                84,
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('\u{1F525}', style: TextStyle(fontSize: 24)),
                    Text('FIRE',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Missile
        Positioned(
          right: 112,
          bottom: 30,
          child: SafeArea(
            child: GestureDetector(
              onTap: g.fireMissile,
              child: _btn(
                g.missiles > 0 ? const Color(0xFF6C5CE7) : Colors.black45,
                64,
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('\u{1F680}', style: TextStyle(fontSize: 20)),
                    Text('${g.missiles}', style: whiteBold),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Shield
        Positioned(
          right: 16,
          bottom: 124,
          child: SafeArea(
            child: GestureDetector(
              onTap: g.useShield,
              child: _btn(
                g.shields > 0 ? const Color(0xFF0984E3) : Colors.black45,
                58,
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('\u{1F6E1}', style: TextStyle(fontSize: 18)),
                    Text('${g.shields}', style: whiteBold),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (g.banner > 0) Center(child: Text(g.bannerText, style: bigStyle)),
        if (g.level == 1 && g.t < 3 && !g.over)
          Align(
            alignment: const Alignment(0, 0.3),
            child: Text('Drag to fly. Auto-fire is on.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ),
        if (g.over) _gameOver(context),
      ],
    );
  }

  Widget _gameOver(BuildContext context) {
    final win = g.won;
    final hasNext = win && g.level < kLevelCount;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        alignment: Alignment.center,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor(context),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(win ? 'Level Complete!' : 'Game Over',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              if (win)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 1; i <= 3; i++)
                      Icon(i <= g.stars ? Icons.star : Icons.star_border,
                          color: Colors.amber, size: 36),
                  ],
                ),
              const SizedBox(height: 8),
              Text('Level ${g.level}  \u2022  Wave ${g.wave}/${g.totalWaves}',
                  style: const TextStyle(fontSize: 17)),
              const SizedBox(height: 6),
              Text('Score: ${g.score}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 6),
              Text('+${g.reward} diamonds',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.blue)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => GameScreen(
                              level: hasNext ? g.level + 1 : g.level))),
                  child: Text(hasNext
                      ? 'Next level'
                      : (win ? 'Play again' : 'Try again')),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Levels'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CombatPainter extends CustomPainter {
  final _CombatGame g;
  _CombatPainter(this.g) : super(repaint: g);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2D7FE0), Color(0xFF8CC8FF), Color(0xFFD9F0FF)],
        ).createShader(rect),
    );

    final s = size.width / kW;
    canvas.save();
    canvas.scale(s);

    // clouds
    final cp = Paint()..color = Colors.white.withOpacity(0.55);
    for (final c in g.clouds) {
      final y = (c.y + g.t * c.speed) % (g.worldH + 200) - 100;
      final x = c.x;
      final k = c.scale;
      canvas.drawCircle(Offset(x, y), 22 * k, cp);
      canvas.drawCircle(Offset(x + 26 * k, y + 6 * k), 18 * k, cp);
      canvas.drawCircle(Offset(x - 24 * k, y + 8 * k), 16 * k, cp);
      canvas.drawCircle(Offset(x + 8 * k, y + 12 * k), 20 * k, cp);
    }

    // pickups
    for (final p in g.picks) {
      _diamond(canvas, p.x, p.y);
    }

    // enemies
    for (final e in g.enemies) {
      switch (e.kind) {
        case _Kind.grunt:
          drawPlane(canvas, Offset(e.x, e.y), 0.6, const Color(0xFFD63031), pi);
          break;
        case _Kind.fast:
          drawPlane(canvas, Offset(e.x, e.y), 0.5, const Color(0xFFE17055), pi);
          break;
        case _Kind.heavy:
          drawPlane(canvas, Offset(e.x, e.y), 0.8, const Color(0xFF2D3436), pi);
          break;
        case _Kind.boss:
          drawPlane(canvas, Offset(e.x, e.y), 1.5, const Color(0xFF8E0000), pi);
          break;
      }
    }

    // enemy bullets
    final ebFill = Paint()..color = const Color(0xFFFF5252);
    final ebEdge = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final b in g.eBullets) {
      canvas.drawCircle(Offset(b.x, b.y), 5, ebFill);
      canvas.drawCircle(Offset(b.x, b.y), 5, ebEdge);
    }

    // player bullets
    final pb = Paint()..color = const Color(0xFFFFEB3B);
    for (final b in g.pBullets) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(b.x - 2, b.y - 9, 4, 16), const Radius.circular(2)),
        pb,
      );
    }

    // missiles
    for (final m in g.missileList) {
      canvas.save();
      canvas.translate(m.x, m.y);
      canvas.rotate(atan2(m.vy, m.vx) + pi / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-3, -14, 6, 22), const Radius.circular(3)),
        Paint()..color = const Color(0xFFECEFF1),
      );
      canvas.drawPath(
        Path()
          ..moveTo(-3, -14)
          ..lineTo(3, -14)
          ..lineTo(0, -22)
          ..close(),
        Paint()..color = const Color(0xFFE53935),
      );
      canvas.restore();
    }

    // player
    final blink = g.invuln > 0 && ((g.invuln * 20).floor() % 2 == 0);
    if (!g.over && !blink) {
      final flame = 30 + sin(g.t * 40) * 5;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(g.px, g.py + 42 + flame / 2),
            width: 14,
            height: flame),
        Paint()..color = const Color(0xFFFFA726).withOpacity(0.9),
      );
      drawPlane(canvas, Offset(g.px, g.py), 0.9, g.plane.color, 0);
    }
    if (g.shieldLeft > 0) {
      canvas.drawCircle(Offset(g.px, g.py), 58,
          Paint()..color = Colors.cyanAccent.withOpacity(0.18));
      canvas.drawCircle(
        Offset(g.px, g.py),
        58,
        Paint()
          ..color = Colors.cyanAccent.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // effects
    for (final f in g.fx) {
      final p = (f.t / f.dur).clamp(0.0, 1.0).toDouble();
      if (f.smoke) {
        canvas.drawCircle(Offset(f.x, f.y), f.size * (0.6 + p * 0.6),
            Paint()..color = Colors.white.withOpacity(0.5 * (1 - p)));
      } else {
        canvas.drawCircle(Offset(f.x, f.y), f.size * (0.5 + p),
            Paint()..color = const Color(0xFFFF7043).withOpacity(1 - p));
        canvas.drawCircle(Offset(f.x, f.y), f.size * (0.3 + p * 0.5),
            Paint()..color = const Color(0xFFFFCA28).withOpacity((1 - p) * 0.9));
      }
    }

    canvas.restore();
  }

  void _diamond(Canvas canvas, double x, double y) {
    final p = Path()
      ..moveTo(x, y - 14)
      ..lineTo(x + 12, y - 4)
      ..lineTo(x, y + 16)
      ..lineTo(x - 12, y - 4)
      ..close();
    canvas.drawPath(p, Paint()..color = const Color(0xFF2E86F5));
    canvas.drawPath(
      p,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final top = Path()
      ..moveTo(x - 12, y - 4)
      ..lineTo(x + 12, y - 4)
      ..lineTo(x, y - 14)
      ..close();
    canvas.drawPath(top, Paint()..color = const Color(0xFF74B9FF));
  }

  @override
  bool shouldRepaint(covariant _CombatPainter oldDelegate) => true;
}
