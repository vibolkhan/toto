import 'card.dart';

/// Hands that win immediately after the deal (tới trắng), in priority order.
enum InstantWin {
  fourTwos('Four 2s'),
  dragon('Dragon (3 to A)'),
  sixPairs('Six pairs'),
  fourTriples('Four triples');

  const InstantWin(this.label);
  final String label;
}

InstantWin? detectInstantWin(List<PlayingCard> hand) {
  final counts = List<int>.filled(13, 0);
  for (final c in hand) {
    counts[c.rank]++;
  }
  if (counts[rankTwo] == 4) return InstantWin.fourTwos;
  if (counts.sublist(0, rankTwo).every((c) => c > 0)) return InstantWin.dragon;
  if (counts.fold<int>(0, (sum, c) => sum + c ~/ 2) >= 6) {
    return InstantWin.sixPairs;
  }
  if (counts.where((c) => c >= 3).length >= 4) return InstantWin.fourTriples;
  return null;
}
