import 'combo.dart';

/// Whether [next] may be played on top of [previous].
/// A null [previous] means the player is leading and anything goes.
bool canBeat(Combo? previous, Combo next) {
  if (previous == null) return true;

  if (previous.type == next.type &&
      previous.length == next.length &&
      next.highest.compareTo(previous.highest) > 0) {
    return true;
  }
  return _bombBeats(previous, next);
}

/// Bomb rules ("chopping"):
/// - A 3-pair double sequence beats a single 2.
/// - Four of a kind beats a single 2, a pair of 2s and any 3-pair double sequence.
/// - A 4-pair double sequence beats a single 2, a pair of 2s,
///   a 3-pair double sequence and any four of a kind.
bool _bombBeats(Combo previous, Combo next) {
  final nextPairs = next.pairCount;
  switch (next.type) {
    case ComboType.doubleSequence when nextPairs == 3:
      return previous.isSingleTwo;
    case ComboType.four:
      return previous.isSingleTwo ||
          previous.isPairOfTwos ||
          previous.pairCount == 3;
    case ComboType.doubleSequence when nextPairs == 4:
      return previous.isSingleTwo ||
          previous.isPairOfTwos ||
          previous.pairCount == 3 ||
          previous.type == ComboType.four;
    default:
      return false;
  }
}
