import 'dart:math';

/// Suits ordered lowest to highest: Spades < Clubs < Diamonds < Hearts.
enum Suit {
  spades('♠'),
  clubs('♣'),
  diamonds('♦'),
  hearts('♥');

  const Suit(this.symbol);
  final String symbol;

  bool get isRed => this == diamonds || this == hearts;
}

/// Ranks ordered lowest to highest: 3 < 4 < ... < K < A < 2.
const List<String> rankLabels = [
  '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A', '2', //
];

/// Index of the rank "2", the highest rank.
const int rankTwo = 12;

/// Index of the rank "A".
const int rankAce = 11;

/// A playing card encoded as a single integer `value = rank * 4 + suit`,
/// so comparing values compares rank first, then suit.
/// 3♠ is 0 and 2♥ is 51. This encoding is shared with the server engine.
class PlayingCard implements Comparable<PlayingCard> {
  const PlayingCard(this.value) : assert(value >= 0 && value < 52);

  factory PlayingCard.of(int rank, Suit suit) =>
      PlayingCard(rank * 4 + suit.index);

  final int value;

  int get rank => value ~/ 4;
  Suit get suit => Suit.values[value % 4];
  String get rankLabel => rankLabels[rank];

  static const PlayingCard threeOfSpades = PlayingCard(0);

  /// Parses short notation such as `3S`, `10H` or `QD` (suits S, C, D, H).
  static PlayingCard parse(String text) {
    final rank = rankLabels.indexOf(text.substring(0, text.length - 1));
    final suit = 'SCDH'.indexOf(text[text.length - 1]);
    if (rank < 0 || suit < 0) throw FormatException('Bad card: $text');
    return PlayingCard(rank * 4 + suit);
  }

  @override
  int compareTo(PlayingCard other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      other is PlayingCard && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$rankLabel${suit.symbol}';
}

List<PlayingCard> fullDeck() => List.generate(52, PlayingCard.new);

/// Shuffles a fresh deck and deals [players] hands of 13 sorted cards.
List<List<PlayingCard>> dealHands({int players = 4, Random? random}) {
  final deck = fullDeck()..shuffle(random ?? Random());
  return List.generate(
    players,
    (i) => deck.sublist(i * 13, i * 13 + 13)..sort(),
  );
}
