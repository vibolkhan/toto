import 'card.dart';
import 'combo.dart';
import 'game_engine.dart';
import 'game_state.dart';

/// Heuristic bot. Returns the cards to play, or null to pass.
List<PlayingCard>? chooseBotMove(GameState s, int seat) {
  final hand = s.hands[seat];
  final legal = legalPlays(s, seat);
  if (legal.isEmpty) return null;

  // Go out immediately when possible.
  for (final c in legal) {
    if (c.length == hand.length) return c.cards;
  }

  final opponentsNearOut = [
    for (var i = 0; i < seatCount; i++)
      if (i != seat && s.isActive(i) && s.hands[i].length <= 3) i,
  ].isNotEmpty;

  final counts = List<int>.filled(13, 0);
  for (final c in hand) {
    counts[c.rank]++;
  }

  // How costly it is to give up these cards. Lower is better.
  double cost(Combo c) {
    var score = c.rankCard.value.toDouble();
    if (c.cards.any((card) => card.rank == rankTwo)) score += 60;
    if (_isBomb(c)) score += 80;
    // Penalise splitting a pair/triple/four for a smaller combo.
    if (c.type == ComboType.single ||
        c.type == ComboType.pair ||
        c.type == ComboType.triple) {
      if (counts[c.highest.rank] > c.length) score += 15;
    }
    if (c.type == ComboType.sequence || c.type == ComboType.doubleSequence) {
      final pairBreaks = c.cards.where((card) => counts[card.rank] >= 2);
      if (c.type == ComboType.sequence) score += pairBreaks.length * 4;
    }
    return score;
  }

  if (s.isLeading) {
    // Lead with something containing the lowest card, preferring to shed
    // more cards at once. Avoid leading 2s and bombs.
    final lowest = hand.first;
    var options = legal.where((c) => c.cards.contains(lowest)).toList();
    if (opponentsNearOut) {
      final nonSingles = legal
          .where((c) => c.type != ComboType.single)
          .toList();
      if (nonSingles.isNotEmpty) {
        options = nonSingles;
      } else {
        // Only singles left: lead high to block the opponent.
        return [hand.last];
      }
    }
    options.sort((a, b) {
      final byLength = b.length.compareTo(a.length);
      return byLength != 0 ? byLength : cost(a).compareTo(cost(b));
    });
    final safe = options.where((c) => !_isBomb(c)).toList();
    return (safe.isNotEmpty ? safe : options).first.cards;
  }

  // Following: play the cheapest card that beats the table.
  final trick = s.trick!;
  final candidates = legal.where((c) {
    final expensive = _isBomb(c) || c.cards.any((x) => x.rank == rankTwo);
    if (!expensive) return true;
    // Chopping a 2 is always worth it; otherwise save power cards for when
    // an opponent is about to go out or the bot is running low.
    return trick.rankCard.rank == rankTwo ||
        opponentsNearOut ||
        hand.length <= 4;
  }).toList()..sort((a, b) => cost(a).compareTo(cost(b)));
  if (candidates.isEmpty) return null;

  // Don't break up a big structure just to follow a low single early on.
  final best = candidates.first;
  final choppingTwo = trick.rankCard.rank == rankTwo;
  if (!choppingTwo && !opponentsNearOut && cost(best) > 70 && hand.length > 6) {
    return null;
  }
  return best.cards;
}

bool _isBomb(Combo c) =>
    c.type == ComboType.four ||
    (c.type == ComboType.doubleSequence && c.pairCount >= 3) ||
    c.isStraightFlush;
