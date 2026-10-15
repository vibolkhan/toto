import 'dart:math';

import 'card.dart';
import 'combo.dart';
import 'game_state.dart';
import 'instant_win.dart';
import 'rules.dart';

class GameError implements Exception {
  const GameError(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Starts a game from already-dealt [hands].
///
/// In the first game ([previousWinner] is null) the holder of 3♠ leads and
/// must include it. Otherwise [previousWinner] leads with anything.
GameState startGame(
  List<List<PlayingCard>> hands, {
  int gameNo = 1,
  int? previousWinner,
}) {
  assert(hands.length == seatCount);
  final sortedHands = [for (final h in hands) List<PlayingCard>.of(h)..sort()];

  final leader =
      previousWinner ??
      sortedHands.indexWhere((h) => h.contains(PlayingCard.threeOfSpades));

  // Instant wins are checked in priority order, ties broken by seat order
  // starting from the leader.
  for (final kind in InstantWin.values) {
    for (var i = 0; i < seatCount; i++) {
      final seat = (leader + i) % seatCount;
      if (detectInstantWin(sortedHands[seat]) == kind) {
        return GameState(
          hands: sortedHands,
          turn: seat,
          gameNo: gameNo,
          finished: [seat],
          instantWin: kind,
          instantWinSeat: seat,
        );
      }
    }
  }

  return GameState(
    hands: sortedHands,
    turn: leader,
    gameNo: gameNo,
    mustPlayThreeOfSpades: previousWinner == null,
  );
}

/// Deals a fresh game. The first game has no [previousWinner].
GameState dealGame({int gameNo = 1, int? previousWinner, Random? random}) =>
    startGame(
      dealHands(random: random),
      gameNo: gameNo,
      previousWinner: previousWinner,
    );

/// Returns an error message if [seat] may not play [cards], otherwise null.
String? validatePlay(GameState s, int seat, List<PlayingCard> cards) {
  if (s.isOver) return 'The game is over';
  if (s.turn != seat) return 'Not your turn';
  final hand = s.hands[seat];
  if (cards.isEmpty) return 'Select cards to play';
  if (!cards.every(hand.contains)) return 'You do not hold those cards';
  final combo = Combo.detect(cards);
  if (combo == null) return 'Not a valid combination';
  if (s.mustPlayThreeOfSpades && !cards.contains(PlayingCard.threeOfSpades)) {
    return 'The first play must include 3♠';
  }
  if (!canBeat(s.trick, combo)) return 'Does not beat the cards on the table';
  return null;
}

GameState play(GameState s, int seat, List<PlayingCard> cards) {
  final error = validatePlay(s, seat, cards);
  if (error != null) throw GameError(error);
  final combo = Combo.detect(cards)!;

  final hands = [
    for (var i = 0; i < seatCount; i++)
      i == seat
          ? (s.hands[i].where((c) => !cards.contains(c)).toList())
          : s.hands[i],
  ];
  final finished = [...s.finished];
  if (hands[seat].isEmpty) finished.add(seat);

  final next = s.copyWith(
    hands: hands,
    trick: () => combo,
    trickOwner: () => seat,
    finished: finished,
    mustPlayThreeOfSpades: false,
    lastAction: LastAction.play(seat, combo.cards),
  );

  final active = [
    for (var i = 0; i < seatCount; i++)
      if (!finished.contains(i)) i,
  ];
  if (active.length == 1) {
    return next.copyWith(finished: [...finished, active.single]);
  }
  return _advance(next, seat);
}

GameState pass(GameState s, int seat) {
  if (s.isOver) throw const GameError('The game is over');
  if (s.turn != seat) throw const GameError('Not your turn');
  if (s.isLeading) throw const GameError('You must lead, you cannot pass');
  final next = s.copyWith(
    passed: {...s.passed, seat},
    lastAction: LastAction.pass(seat),
  );
  return _advance(next, seat);
}

/// Moves the turn clockwise from [from], clearing the trick once every
/// other active seat has passed.
GameState _advance(GameState s, int from) {
  final owner = s.trickOwner!;
  bool canRespond(int seat) =>
      seat != owner && s.isActive(seat) && !s.passed.contains(seat);

  final anyoneCanRespond = List.generate(seatCount, (i) => i).any(canRespond);

  if (!anyoneCanRespond) {
    // Trick is won by its owner, who leads next. If the owner has gone out,
    // the lead passes to the next active seat clockwise.
    var leader = owner;
    while (!s.isActive(leader)) {
      leader = (leader + 1) % seatCount;
    }
    return s.copyWith(
      turn: leader,
      trick: () => null,
      trickOwner: () => null,
      passed: const {},
    );
  }

  var seat = (from + 1) % seatCount;
  while (!canRespond(seat)) {
    seat = (seat + 1) % seatCount;
  }
  return s.copyWith(turn: seat);
}

/// Every distinct combo that can be formed from [hand]. Sequences pick the
/// lowest suit for all but their top card to keep the list small.
List<Combo> possibleCombos(List<PlayingCard> hand) {
  final byRank = List.generate(13, (_) => <PlayingCard>[]);
  for (final c in hand) {
    byRank[c.rank].add(c);
  }
  for (final cards in byRank) {
    cards.sort();
  }

  final result = <Combo>[];
  void add(List<PlayingCard> cards) {
    final combo = Combo.detect(cards);
    if (combo != null) result.add(combo);
  }

  // Singles, pairs, triples, four of a kind.
  for (final cards in byRank) {
    for (final subset in _subsets(cards)) {
      add(subset);
    }
  }

  // Sequences of length >= 3.
  for (var start = 0; start < 13; start++) {
    for (var end = start + 2; end < 13; end++) {
      if (byRank[end].isEmpty) break;
      if (byRank.sublist(start, end + 1).any((r) => r.isEmpty)) break;
      final base = [for (var r = start; r < end; r++) byRank[r].first];
      for (final top in byRank[end]) {
        add([...base, top]);
      }
    }
  }

  // Double sequences of >= 2 pairs.
  for (var start = 0; start < 13; start++) {
    for (var end = start + 1; end < 13; end++) {
      if (byRank.sublist(start, end + 1).any((r) => r.length < 2)) break;
      final base = [for (var r = start; r < end; r++) ...byRank[r].take(2)];
      for (final topPair in _subsets(byRank[end]).where((p) => p.length == 2)) {
        add([...base, ...topPair]);
      }
    }
  }

  // Full houses: a triple plus a pair of an adjacent rank, below the 2s.
  for (var t = 0; t < rankTwo; t++) {
    for (final p in [t - 1, t + 1]) {
      if (p < 0 || p >= rankTwo) continue;
      final pairs = _subsets(byRank[p]).where((c) => c.length == 2).toList();
      for (final triple in _subsets(byRank[t]).where((c) => c.length == 3)) {
        for (final pair in pairs) {
          add([...triple, ...pair]);
        }
      }
    }
  }
  return result;
}

/// Combos from [s.hands[seat]] that are legal right now.
List<Combo> legalPlays(GameState s, int seat) {
  return possibleCombos(
    s.hands[seat],
  ).where((c) => validatePlay(s, seat, c.cards) == null).toList();
}

Iterable<List<PlayingCard>> _subsets(List<PlayingCard> cards) sync* {
  final n = cards.length;
  for (var mask = 1; mask < (1 << n); mask++) {
    yield [
      for (var i = 0; i < n; i++)
        if (mask & (1 << i) != 0) cards[i],
    ];
  }
}
