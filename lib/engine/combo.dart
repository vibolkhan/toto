import 'card.dart';

enum ComboType { single, pair, triple, four, sequence, doubleSequence }

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

  bool get isSingleTwo => type == ComboType.single && highest.rank == rankTwo;
  bool get isPairOfTwos => type == ComboType.pair && highest.rank == rankTwo;

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

    if (n >= 6 && n.isEven) {
      final pairRanks = <int>[];
      for (var i = 0; i < n; i += 2) {
        if (ranks[i] != ranks[i + 1]) return null;
        pairRanks.add(ranks[i]);
      }
      if (_isConsecutive(pairRanks)) {
        return Combo._(ComboType.doubleSequence, sorted);
      }
    }
    return null;
  }

  static bool _isConsecutive(List<int> ranks) {
    for (var i = 1; i < ranks.length; i++) {
      if (ranks[i] != ranks[i - 1] + 1) return false;
    }
    return true;
  }

  @override
  String toString() => '${type.name}${cards.toString()}';
}
