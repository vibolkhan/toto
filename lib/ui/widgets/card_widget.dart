import 'package:flutter/material.dart';

import '../../engine/card.dart';

const double cardAspect = 1.4;

class CardWidget extends StatelessWidget {
  const CardWidget({
    super.key,
    required this.card,
    this.width = 56,
    this.selected = false,
  });

  final PlayingCard card;
  final double width;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = card.suit.isRed
        ? const Color(0xFFD32F2F)
        : const Color(0xFF1A1A1A);
    final corner = TextStyle(
      color: color,
      fontWeight: FontWeight.w800,
      fontSize: width * 0.3,
      height: 1,
    );
    return Container(
      width: width,
      height: width * cardAspect,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.12),
        border: Border.all(
          color: selected ? const Color(0xFFFFC107) : const Color(0xFFBDBDBD),
          width: selected ? 2.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(1, 2)),
        ],
      ),
      padding: EdgeInsets.all(width * 0.07),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(card.rankLabel, style: corner),
                Text(card.suit.symbol, style: corner),
              ],
            ),
          ),
          Align(
            alignment: const Alignment(0.3, 0.55),
            child: Text(
              card.suit.symbol,
              style: TextStyle(color: color, fontSize: width * 0.55, height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

class CardBack extends StatelessWidget {
  const CardBack({super.key, this.width = 28});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * cardAspect,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.12),
        border: Border.all(color: Colors.white, width: 1.5),
        gradient: const LinearGradient(
          colors: [Color(0xFF8E1B1B), Color(0xFFC62828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1)),
        ],
      ),
    );
  }
}
