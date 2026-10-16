import 'package:flutter_test/flutter_test.dart';
import 'package:toto/engine/card.dart';
import 'package:toto/engine/game_engine.dart';
import 'package:toto/engine/game_state.dart';
import 'package:toto/game/game_controller.dart';
import 'package:toto/game/game_sounds.dart';

List<PlayingCard> c(String s) => s.split(' ').map(PlayingCard.parse).toList();

TableView viewOf(GameState s) => TableView(
  mySeat: 0,
  seatNames: const ['Me', 'A', 'B', 'C'],
  isBot: const [false, true, true, true],
  myHand: s.hands[0],
  handCounts: [for (final h in s.hands) h.length],
  turn: s.turn,
  gameNo: s.gameNo,
  trickCards: s.trick?.cards ?? const [],
  trickOwner: s.trickOwner,
  passed: s.passed,
  finished: s.finished,
  isOver: s.isOver,
  lastAction: s.lastAction,
  instantWinSeat: s.instantWinSeat,
);

void main() {
  test('deal, plays, pass, my turn', () {
    var s = startGame([c('5S 6S'), c('3S 7S 7C'), c('4S 8S'), c('9S 10S')]);
    var v = viewOf(s);
    expect(soundsFor(null, v), [Sfx.deal]);

    s = play(s, 1, c('3S'));
    expect(soundsFor(v, v = viewOf(s)), [Sfx.play]);
    s = pass(s, 2);
    expect(soundsFor(v, v = viewOf(s)), [Sfx.pass]);
    s = play(s, 3, c('9S'));
    expect(soundsFor(v, v = viewOf(s)), [Sfx.play, Sfx.turn]);
    // Rebuilding the same state makes no sound.
    expect(soundsFor(v, viewOf(s)), isEmpty);
  });

  test('a bomb on a 2 that also empties the hand', () {
    var s = startGame(
      [c('3S 4S 5S 6S 7S'), c('2H 8C'), c('9C 9D 9H 9S'), c('10C JC')],
      gameNo: 2,
      previousWinner: 1,
    );
    var v = viewOf(s);
    s = play(s, 1, c('2H'));
    expect(soundsFor(v, v = viewOf(s)), [Sfx.play]);
    s = play(s, 2, c('9C 9D 9H 9S'));
    expect(soundsFor(v, v = viewOf(s)), [Sfx.bomb, Sfx.out]);
  });

  test('win jingle for me, lose jingle when someone else wins', () {
    GameState finish(List<int> order) {
      final hands = [c('3S'), c('4S'), c('5S'), c('6S')];
      var s = startGame(hands, gameNo: 2, previousWinner: order.first);
      for (final seat in order.take(3)) {
        s = play(s, seat, hands[seat]);
      }
      return s;
    }

    GameState beforeEnd(List<int> order) {
      final hands = [c('3S'), c('4S'), c('5S'), c('6S')];
      var s = startGame(hands, gameNo: 2, previousWinner: order.first);
      for (final seat in order.take(2)) {
        s = play(s, seat, hands[seat]);
      }
      return s;
    }

    expect(soundsFor(viewOf(beforeEnd([0, 1, 2])), viewOf(finish([0, 1, 2]))), [
      Sfx.play,
      Sfx.win,
    ]);
    expect(soundsFor(viewOf(beforeEnd([1, 2, 3])), viewOf(finish([1, 2, 3]))), [
      Sfx.play,
      Sfx.lose,
    ]);
  });
}
