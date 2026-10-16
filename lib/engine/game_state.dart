import 'card.dart';
import 'combo.dart';
import 'instant_win.dart';

const int seatCount = 4;

const List<int> zeroScores = [0, 0, 0, 0];

/// The most recent thing a seat did, for display.
class LastAction {
  const LastAction.play(this.seat, this.cards) : passed = false;
  const LastAction.pass(this.seat) : passed = true, cards = const [];

  final int seat;
  final bool passed;
  final List<PlayingCard> cards;
}

/// Immutable snapshot of one game of Tien Len.
class GameState {
  const GameState({
    required this.hands,
    required this.turn,
    required this.gameNo,
    this.trick,
    this.trickOwner,
    this.passed = const {},
    this.finished = const [],
    this.mustPlayThreeOfSpades = false,
    this.lastAction,
    this.instantWin,
    this.instantWinSeat,
    this.scores = zeroScores,
    this.gamePoints = zeroScores,
  });

  /// Cards held by each seat, sorted low to high.
  final List<List<PlayingCard>> hands;

  /// Seat whose turn it is.
  final int turn;

  /// 1 for the first game of a session; later games are led by the previous winner.
  final int gameNo;

  /// Combo currently on the table, or null when the turn player is leading.
  final Combo? trick;

  /// Seat that played [trick].
  final int? trickOwner;

  /// Seats locked out of the current trick.
  final Set<int> passed;

  /// Seats in the order they emptied their hands. When the game is over
  /// this holds every seat (1st place first).
  final List<int> finished;

  /// True until the opening play of the first game, which must contain 3♠.
  final bool mustPlayThreeOfSpades;

  final LastAction? lastAction;

  final InstantWin? instantWin;
  final int? instantWinSeat;

  /// Running total for each seat over the session, including this game.
  final List<int> scores;

  /// Points each seat has won or lost in this game so far.
  final List<int> gamePoints;

  bool get isOver => finished.length == seatCount || instantWin != null;

  bool get isLeading => trick == null;

  bool isActive(int seat) => !finished.contains(seat);

  /// 1-based place of [seat], or null while it is still playing.
  /// After an instant win every other seat shares 2nd place.
  int? placeOf(int seat) {
    if (instantWin != null) return seat == instantWinSeat ? 1 : 2;
    final i = finished.indexOf(seat);
    return i < 0 ? null : i + 1;
  }

  int? get winner =>
      instantWinSeat ?? (finished.isEmpty ? null : finished.first);

  GameState copyWith({
    List<List<PlayingCard>>? hands,
    int? turn,
    Combo? Function()? trick,
    int? Function()? trickOwner,
    Set<int>? passed,
    List<int>? finished,
    bool? mustPlayThreeOfSpades,
    LastAction? lastAction,
    List<int>? scores,
    List<int>? gamePoints,
  }) {
    return GameState(
      hands: hands ?? this.hands,
      turn: turn ?? this.turn,
      gameNo: gameNo,
      trick: trick != null ? trick() : this.trick,
      trickOwner: trickOwner != null ? trickOwner() : this.trickOwner,
      passed: passed ?? this.passed,
      finished: finished ?? this.finished,
      mustPlayThreeOfSpades:
          mustPlayThreeOfSpades ?? this.mustPlayThreeOfSpades,
      lastAction: lastAction ?? this.lastAction,
      instantWin: instantWin,
      instantWinSeat: instantWinSeat,
      scores: scores ?? this.scores,
      gamePoints: gamePoints ?? this.gamePoints,
    );
  }

  /// Adds [deltas] to both this game's points and the running totals.
  GameState addPoints(List<int> deltas) {
    return copyWith(
      scores: [for (var i = 0; i < seatCount; i++) scores[i] + deltas[i]],
      gamePoints: [
        for (var i = 0; i < seatCount; i++) gamePoints[i] + deltas[i],
      ],
    );
  }
}
