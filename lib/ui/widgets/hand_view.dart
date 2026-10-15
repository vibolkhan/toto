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
  });

  final List<PlayingCard> cards;
  final Set<PlayingCard> selected;
  final ValueChanged<PlayingCard> onToggle;
  final bool enabled;

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
                  for (var i = 0; i < n; i++)
                    AnimatedPositioned(
                      key: ValueKey(cards[i].value),
                      duration: const Duration(milliseconds: 150),
                      left: i * step,
                      top: selected.contains(cards[i]) ? 0 : _lift,
                      child: GestureDetector(
                        onTap: enabled ? () => onToggle(cards[i]) : null,
                        child: CardWidget(
                          card: cards[i],
                          width: cardWidth,
                          selected: selected.contains(cards[i]),
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
