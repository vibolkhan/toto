import 'package:flutter/foundation.dart';

import '../engine/card.dart';
import '../engine/combo.dart';
import '../engine/game_state.dart';
import '../engine/rules.dart';

/// What one player sees of the table. Built from the full engine state in
/// bot mode, or from the server's public state plus the player's own hand
/// in online mode.
class TableView {
  const TableView({
    required this.mySeat,
    required this.seatNames,
    required this.isBot,
    required this.myHand,
    required this.handCounts,
    required this.turn,
    required this.gameNo,
    this.trickCards = const [],
    this.trickOwner,
    this.passed = const {},
    this.finished = const [],
    this.isOver = false,
    this.mustPlayThreeOfSpades = false,
    this.lastAction,
    this.instantWinLabel,
    this.instantWinSeat,
  });

  final int mySeat;
  final List<String> seatNames;
  final List<bool> isBot;
  final List<PlayingCard> myHand;
  final List<int> handCounts;
  final int turn;
  final int gameNo;
  final List<PlayingCard> trickCards;
  final int? trickOwner;
  final Set<int> passed;
  final List<int> finished;
  final bool isOver;
  final bool mustPlayThreeOfSpades;
  final LastAction? lastAction;
  final String? instantWinLabel;
  final int? instantWinSeat;

  bool get isMyTurn => !isOver && turn == mySeat;
  bool get isLeading => trickCards.isEmpty;
  int? get winner =>
      instantWinSeat ?? (finished.isEmpty ? null : finished.first);

  int? placeOf(int seat) {
    if (instantWinSeat != null) return seat == instantWinSeat ? 1 : 2;
    final i = finished.indexOf(seat);
    return i < 0 ? null : i + 1;
  }

  /// Client-side check used to enable the Play button and show hints.
  /// The authoritative check happens in the engine (or on the server).
  String? validateSelection(List<PlayingCard> selected) {
    if (!isMyTurn) return 'Wait for your turn';
    if (selected.isEmpty) return 'Select cards to play';
    final combo = Combo.detect(selected);
    if (combo == null) return 'Not a valid combination';
    if (mustPlayThreeOfSpades &&
        !selected.contains(PlayingCard.threeOfSpades)) {
      return 'The first play must include 3♠';
    }
    final trick = isLeading ? null : Combo.detect(trickCards);
    if (!canBeat(trick, combo)) return 'Does not beat the table';
    return null;
  }
}

/// The table UI talks only to this interface, so the same screen renders
/// bot games and online games.
abstract class GameController extends ChangeNotifier {
  TableView? get view;

  /// Set while waiting for the server to respond.
  bool get busy;

  /// Latest error to show the player; cleared on the next action.
  String? get error;

  /// Whether this player may start the next game once the current one ends.
  bool get canStartNextGame;

  /// If non-null, the player is asked to confirm this before leaving the table.
  String? get leaveWarning => null;

  Future<void> play(List<PlayingCard> cards);
  Future<void> pass();
  Future<void> nextGame();

  /// Called when the player leaves the table.
  Future<void> leave() async {}
}
