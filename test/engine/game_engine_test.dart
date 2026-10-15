import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:toto/engine/bot.dart';
import 'package:toto/engine/card.dart';
import 'package:toto/engine/game_engine.dart';
import 'package:toto/engine/game_state.dart';

List<PlayingCard> c(String s) => s.split(' ').map(PlayingCard.parse).toList();

/// Hands that avoid instant wins; seat 1 holds 3♠.
GameState sampleGame() => startGame([
  c('4S 5C 6D 7H 8S 9C 10D JH QS KC AD 2H KD'),
  c('3S 4C 5D 6H 7S 8C 9D 10H JS QC 2S AH 3C'),
  c('3D 4D 5H 6S 7C 8D 9H 10S JC QD 2C AS 4H'),
  c('3H 5S 6C 7D 8H 9S 10C JD QH KS AC KH 2D'),
]);

void main() {
  test('holder of 3♠ leads the first game and must include it', () {
    final s = sampleGame();
    expect(s.turn, 1);
    expect(() => play(s, 1, c('4C')), throwsA(isA<GameError>()));
    final next = play(s, 1, c('3S'));
    expect(next.turn, 2);
    expect(next.mustPlayThreeOfSpades, isFalse);
  });

  test('cannot play out of turn or pass when leading', () {
    final s = sampleGame();
    expect(() => play(s, 0, c('4S')), throwsA(isA<GameError>()));
    expect(() => pass(s, 1), throwsA(isA<GameError>()));
  });

  test('passing locks a player out until the trick clears', () {
    var s = sampleGame();
    s = play(s, 1, c('3S')); // seat 2
    s = pass(s, 2); // seat 3
    s = play(s, 3, c('5S')); // seat 0
    s = play(s, 0, c('6D')); // seat 1 (seat 2 has passed)
    expect(s.turn, 1);
    s = play(s, 1, c('7S')); // skips 2
    expect(s.turn, 3);
    s = pass(s, 3);
    s = pass(s, 0);
    // Everyone else passed: seat 1 leads a fresh trick, seat 2 is unlocked.
    expect(s.turn, 1);
    expect(s.isLeading, isTrue);
    expect(s.passed, isEmpty);
  });

  test('a player going out ends their participation and lead moves on', () {
    var s = startGame([c('3S'), c('4S 4C'), c('5S 5C'), c('6S 6C')]);
    s = play(s, 0, c('3S'));
    expect(s.finished, [0]);
    expect(s.turn, 1);
    s = pass(s, 1);
    s = pass(s, 2);
    s = pass(s, 3);
    // Owner (seat 0) is out, so the next active seat leads.
    expect(s.turn, 1);
    expect(s.isLeading, isTrue);
  });

  test('game ends with full finishing order', () {
    var s = startGame([c('3S'), c('4S'), c('5S'), c('6S')]);
    s = play(s, 0, c('3S'));
    s = play(s, 1, c('4S'));
    s = play(s, 2, c('5S'));
    expect(s.isOver, isTrue);
    expect(s.finished, [0, 1, 2, 3]);
    expect(s.placeOf(3), 4);
  });

  test('instant win ends the game immediately', () {
    final s = startGame([
      c('2S 2C 2D 2H 3S 4S 5S 6S 7S 8S 9S 10S JS'),
      c('3C 4C 5C 6C 7C 8C 9C 10C JC QC KC AC QS'),
      c('3D 4D 5D 6D 7D 8D 9D 10D JD QD KD AD KS'),
      c('3H 4H 5H 6H 7H 8H 9H 10H JH QH KH AH AS'),
    ]);
    // Seat 0 has four 2s, which outranks the dragons of the other seats.
    expect(s.isOver, isTrue);
    expect(s.winner, 0);
    expect(s.placeOf(2), 2);
  });

  test('previous winner leads subsequent games with anything', () {
    final s = startGame(sampleGame().hands, gameNo: 2, previousWinner: 3);
    expect(s.turn, 3);
    expect(s.mustPlayThreeOfSpades, isFalse);
    expect(validatePlay(s, 3, c('KS')), isNull);
  });

  test('1000 bot-only games all finish legally', () {
    final random = Random(42);
    int? previousWinner;
    for (var g = 0; g < 1000; g++) {
      var s = dealGame(
        gameNo: g + 1,
        previousWinner: previousWinner,
        random: random,
      );
      var moves = 0;
      while (!s.isOver) {
        final move = chooseBotMove(s, s.turn);
        s = move == null ? pass(s, s.turn) : play(s, s.turn, move);
        expect(++moves, lessThan(500), reason: 'game $g did not terminate');
      }
      if (s.instantWin == null) {
        expect(s.finished.toSet().length, seatCount);
        expect(s.hands[s.finished.last], isNotEmpty);
        for (final seat in s.finished.take(3)) {
          expect(s.hands[seat], isEmpty);
        }
      }
      previousWinner = s.winner;
    }
  });
}
