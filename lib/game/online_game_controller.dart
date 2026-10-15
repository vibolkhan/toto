import 'dart:async';

import '../engine/card.dart';
import '../engine/game_state.dart';
import '../online/supabase_service.dart';
import 'game_controller.dart';

/// Online mode: renders the server's public game state plus this player's
/// own hand, and sends moves to the `tienlen` Edge Function.
class OnlineGameController extends GameController {
  OnlineGameController({required this.roomId, required this.code}) {
    _subs = [
      SupabaseService.room(roomId).listen((r) => _update(() => _room = r)),
      SupabaseService.players(
        roomId,
      ).listen((p) => _update(() => _players = p)),
      SupabaseService.game(roomId).listen((g) => _update(() => _game = g)),
      SupabaseService.myHands(roomId).listen((h) => _update(() => _hands = h)),
    ];
  }

  final String roomId;
  final String code;

  late final List<StreamSubscription<Object?>> _subs;
  Map<String, dynamic>? _room;
  List<Map<String, dynamic>> _players = const [];
  Map<String, dynamic>? _game;
  List<Map<String, dynamic>> _hands = const [];
  bool _busy = false;
  String? _error;

  void _update(void Function() change) {
    change();
    notifyListeners();
  }

  int? get _mySeat {
    final uid = SupabaseService.userId;
    for (final p in _players) {
      if (p['user_id'] == uid) return p['seat'] as int;
    }
    return null;
  }

  bool get isHost =>
      _room != null && _room!['host_id'] == SupabaseService.userId;

  @override
  TableView? get view {
    final seat = _mySeat;
    final game = _game;
    if (seat == null || game == null || _players.length < seatCount) {
      return null;
    }
    final s = (game['state'] as Map).cast<String, dynamic>();
    List<int> ints(Object? v) => [for (final x in (v as List? ?? [])) x as int];
    List<PlayingCard> cards(Object? v) => ints(v).map(PlayingCard.new).toList();

    final handRow = _hands.where((h) => h['seat'] == seat).firstOrNull;
    final last = s['lastAction'] as Map?;
    final players = [..._players]
      ..sort((a, b) => (a['seat'] as int).compareTo(b['seat'] as int));

    return TableView(
      mySeat: seat,
      seatNames: [for (final p in players) p['display_name'] as String],
      isBot: [for (final p in players) p['is_bot'] as bool],
      myHand: cards(handRow?['cards'])..sort(),
      handCounts: ints(s['handCounts']),
      turn: s['turn'] as int,
      gameNo: s['gameNo'] as int,
      trickCards: cards(s['trick']),
      trickOwner: s['trickOwner'] as int?,
      passed: ints(s['passed']).toSet(),
      finished: ints(s['finished']),
      isOver: s['isOver'] as bool,
      mustPlayThreeOfSpades: s['mustPlayThreeOfSpades'] as bool,
      lastAction: last == null
          ? null
          : last['passed'] as bool
          ? LastAction.pass(last['seat'] as int)
          : LastAction.play(last['seat'] as int, cards(last['cards'])),
      instantWinLabel: _instantWinLabels[s['instantWin']],
      instantWinSeat: s['instantWinSeat'] as int?,
    );
  }

  static const _instantWinLabels = {
    'fourTwos': 'Four 2s',
    'dragon': 'Dragon (3 to A)',
    'sixPairs': 'Six pairs',
    'fourTriples': 'Four triples',
  };

  @override
  bool get busy => _busy;

  @override
  String? get error => _error;

  @override
  bool get canStartNextGame => isHost && (view?.isOver ?? false);

  @override
  String? get leaveWarning =>
      'Leave this game? A bot will take over your seat.';

  Future<void> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on OnlineError catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Connection problem, please try again';
    }
    _busy = false;
    notifyListeners();
  }

  @override
  Future<void> play(List<PlayingCard> cards) =>
      _run(() => SupabaseService.play(roomId, cards));

  @override
  Future<void> pass() => _run(() => SupabaseService.pass(roomId));

  @override
  Future<void> nextGame() => _run(() => SupabaseService.nextGame(roomId));

  @override
  Future<void> leave() => SupabaseService.leaveRoom(roomId);

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
