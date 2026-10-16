import 'dart:async';
import 'dart:math';

import '../engine/bot.dart';
import '../engine/card.dart';
import '../engine/game_engine.dart' as engine;
import '../engine/game_state.dart';
import 'game_controller.dart';

/// Bot mode: one human at seat 0 against three bots, all on this device.
class LocalGameController extends GameController {
  LocalGameController({
    required String playerName,
    Random? random,
    this.botDelay = const Duration(milliseconds: 900),
    this.dealDelay = dealDuration,
  }) : _random = random ?? Random(),
       _names = [playerName, 'Bot 1', 'Bot 2', 'Bot 3'] {
    _state = engine.dealGame(random: _random);
    _scheduleBots(afterDeal: true);
  }

  static const int humanSeat = 0;

  final Random _random;
  final List<String> _names;
  final Duration botDelay;

  /// Extra wait before the first move of a game, while the cards are dealt.
  final Duration dealDelay;
  late GameState _state;
  Timer? _botTimer;
  String? _error;
  bool _disposed = false;

  GameState get state => _state;

  @override
  TableView get view => TableView(
    mySeat: humanSeat,
    seatNames: _names,
    isBot: const [false, true, true, true],
    myHand: _state.hands[humanSeat],
    handCounts: [for (final h in _state.hands) h.length],
    turn: _state.turn,
    gameNo: _state.gameNo,
    trickCards: _state.trick?.cards ?? const [],
    trickOwner: _state.trickOwner,
    passed: _state.passed,
    finished: _state.finished,
    isOver: _state.isOver,
    mustPlayThreeOfSpades: _state.mustPlayThreeOfSpades,
    lastAction: _state.lastAction,
    instantWinLabel: _state.instantWin?.label,
    instantWinSeat: _state.instantWinSeat,
    scores: _state.scores,
    gamePoints: _state.gamePoints,
  );

  @override
  bool get busy => false;

  @override
  String? get error => _error;

  @override
  bool get canStartNextGame => _state.isOver;

  @override
  Future<void> play(List<PlayingCard> cards) async {
    _apply(() => engine.play(_state, humanSeat, cards));
  }

  @override
  Future<void> pass() async {
    _apply(() => engine.pass(_state, humanSeat));
  }

  @override
  Future<void> nextGame() async {
    if (!_state.isOver) return;
    _state = engine.dealGame(
      gameNo: _state.gameNo + 1,
      previousWinner: _state.winner,
      previousScores: _state.scores,
      random: _random,
    );
    _error = null;
    notifyListeners();
    _scheduleBots(afterDeal: true);
  }

  void _apply(GameState Function() action) {
    try {
      _state = action();
      _error = null;
    } on engine.GameError catch (e) {
      _error = e.message;
    }
    notifyListeners();
    _scheduleBots();
  }

  void _scheduleBots({bool afterDeal = false}) {
    _botTimer?.cancel();
    if (_disposed || _state.isOver || _state.turn == humanSeat) return;
    _botTimer = Timer(afterDeal ? dealDelay + botDelay : botDelay, () {
      final seat = _state.turn;
      final move = chooseBotMove(_state, seat);
      _state = move == null
          ? engine.pass(_state, seat)
          : engine.play(_state, seat, move);
      notifyListeners();
      _scheduleBots();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _botTimer?.cancel();
    super.dispose();
  }
}
