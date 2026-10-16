import 'combo.dart';

/// Whether [next] may be played on top of [previous].
/// A null [previous] means the player is leading and anything goes.
bool canBeat(Combo? previous, Combo next) {
  if (previous == null) return true;

  // A single-suit run is only beaten by a higher single-suit run of the same
  // length (any suit).
  if (previous.isSuitedSequence) {
    return next.isSuitedSequence &&
        next.length == previous.length &&
        next.highest.compareTo(previous.highest) > 0;
  }

  if (previous.type == next.type &&
      previous.length == next.length &&
      next.rankCard.compareTo(previous.rankCard) > 0) {
    return true;
  }
  return _bombBeats(previous, next);
}

/// Bomb rules ("chopping"):
/// - Four of a kind beats a single 2.
/// - A 4-pair double sequence beats a pair of 2s, a 3-pair double sequence
///   and any four of a kind (but not a single 2).
/// - A 5-card straight flush beats a single 2 and any four of a kind.
/// A 3-pair double sequence only beats a lower 3-pair double sequence.
bool _bombBeats(Combo previous, Combo next) {
  if (next.isStraightFlush) {
    return previous.isSingleTwo || previous.type == ComboType.four;
  }
  final nextPairs = next.pairCount;
  switch (next.type) {
    case ComboType.four:
      return previous.isSingleTwo;
    case ComboType.doubleSequence when nextPairs == 4:
      return previous.isPairOfTwos ||
          previous.pairCount == 3 ||
          previous.type == ComboType.four;
    default:
      return false;
  }
}

/// Points a bomb [next] takes from the player who played [previous]:
/// 20 for a pair of 2s, 10 for a single 2, a 3-pair double sequence or
/// another bomb, otherwise 0.
int chopPoints(Combo previous, Combo next) {
  if (!next.isBomb) return 0;
  if (previous.isPairOfTwos) return 20;
  if (previous.isSingleTwo || previous.isBomb || previous.pairCount == 3) {
    return 10;
  }
  return 0;
}

/// Points for finishing 1st, 2nd, 3rd and 4th.
const placePoints = [10, 5, -5, -10];

/// An instant winner takes this many points from each other player.
const instantWinPoints = 10;
