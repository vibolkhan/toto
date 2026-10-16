import 'dart:math';

import 'package:flutter/material.dart';

import '../../engine/card.dart';
import 'card_widget.dart';

/// The player's own hand: an overlapping fan of cards that rise when tapped.
class HandView extends StatelessWidget {
  const HandView({
    super.key,
    required this.cards,
    required this.selected,
    required this.onToggle,
    this.enabled = true,
    this.dealt,
  });

  final List<PlayingCard> cards;
  final Set<PlayingCard> selected;
  final ValueChanged<PlayingCard> onToggle;
  final bool enabled;

  /// While dealing, how many cards (from the left) have arrived so far.
  /// Null shows the whole hand.
  final int? dealt;

  static const double _lift = 18;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final cardWidth = min(72.0, max(44.0, maxWidth / 6.5));
        final n = cards.length;
        final step = n <= 1
            ? 0.0
            : min(cardWidth + 4, (maxWidth - cardWidth) / (n - 1));
        final totalWidth = n == 0 ? 0.0 : cardWidth + step * (n - 1);
        final height = cardWidth * cardAspect + _lift;

        return SizedBox(
          height: height,
          child: Center(
            child: SizedBox(
              width: totalWidth,
              height: height,
              child: Stack(
                children: [
                  for (var i = 0; i < min(n, dealt ?? n); i++)
                    AnimatedPositioned(
                      key: ValueKey(cards[i].value),
                      duration: const Duration(milliseconds: 150),
                      left: i * step,
                      top: selected.contains(cards[i]) ? 0 : _lift,
                      child: _DealIn(
                        child: GestureDetector(
                          onTap: enabled ? () => onToggle(cards[i]) : null,
                          child: CardWidget(
                            card: cards[i],
                            width: cardWidth,
                            selected: selected.contains(cards[i]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Drops a card into place the first time it is shown.
class _DealIn extends StatelessWidget {
  const _DealIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, -40 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
