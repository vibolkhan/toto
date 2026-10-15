import 'card.dart';

enum ComboType { single, pair, triple, four, sequence, doubleSequence, fullHouse }

/// A legal set of cards played together.
class Combo {
  Combo._(this.type, this.cards);

  final ComboType type;

  /// Cards sorted from lowest to highest.
  final List<PlayingCard> cards;

  PlayingCard get highest => cards.last;
  int get length => cards.length;

  /// Number of pairs in a double sequence.
  int get pairCount => type == ComboType.doubleSequence ? cards.length ~/ 2 : 0;

  /// The card that decides which combo of the same type is higher. For a
  /// full house this is the top card of the triple; the pair is ignored.
  PlayingCard get rankCard {
    if (type != ComboType.fullHouse) return highest;
    return cards[4].rank == cards[2].rank ? cards[4] : cards[2];
  }

  bool get isSingleTwo => type == ComboType.single && highest.rank == rankTwo;
  bool get isPairOfTwos => type == ComboType.pair && highest.rank == rankTwo;

  /// A sequence whose cards all share one suit.
  bool get isSuitedSequence =>
      type == ComboType.sequence &&
      cards.every((c) => c.suit == cards.first.suit);

  /// A 5-card sequence whose cards all share one suit.
  bool get isStraightFlush => isSuitedSequence && length == 5;

  /// Returns the combo formed by [cards], or null if they are not a legal play.
  static Combo? detect(Iterable<PlayingCard> cards) {
    final sorted = cards.toList()..sort();
    final n = sorted.length;
    if (n == 0 || sorted.toSet().length != n) return null;

    final ranks = sorted.map((c) => c.rank).toList();
    final allSameRank = ranks.every((r) => r == ranks.first);

    if (allSameRank) {
      return switch (n) {
        1 => Combo._(ComboType.single, sorted),
        2 => Combo._(ComboType.pair, sorted),
        3 => Combo._(ComboType.triple, sorted),
        4 => Combo._(ComboType.four, sorted),
        _ => null,
      };
    }

    if (n >= 3 && _isConsecutive(ranks)) {
      return Combo._(ComboType.sequence, sorted);
    }

    if (n >= 4 && n.isEven) {
      final pairRanks = <int>[];
      for (var i = 0; i < n; i += 2) {
        if (ranks[i] != ranks[i + 1]) return null;
        pairRanks.add(ranks[i]);
      }
      if (_isConsecutive(pairRanks)) {
        return Combo._(ComboType.doubleSequence, sorted);
      }
    }

    // Full house: a triple and a pair of adjacent ranks (no 2s).
    if (n == 5 &&
        ((ranks[0] == ranks[2] && ranks[3] == ranks[4]) ||
            (ranks[0] == ranks[1] && ranks[2] == ranks[4])) &&
        _isConsecutive([ranks.first, ranks.last])) {
      return Combo._(ComboType.fullHouse, sorted);
    }
    return null;
  }

  /// Runs top out at A: a 2 can never be part of a sequence.
  static bool _isConsecutive(List<int> ranks) {
    if (ranks.last == rankTwo) return false;
    for (var i = 1; i < ranks.length; i++) {
      if (ranks[i] != ranks[i - 1] + 1) return false;
    }
    return true;
  }

  @override
  String toString() => '${type.name}${cards.toString()}';
}
