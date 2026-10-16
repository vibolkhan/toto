import 'package:flutter/material.dart';

import 'card_widget.dart';

/// Name plate for a seat: avatar, card count and status badge.
class SeatPlate extends StatelessWidget {
  const SeatPlate({
    super.key,
    required this.name,
    required this.cardCount,
    required this.isTurn,
    required this.isBot,
    this.passed = false,
    this.place,
    this.score = 0,
    this.showBacks = true,
  });

  final String name;
  final int cardCount;
  final bool isTurn;
  final bool isBot;
  final bool passed;
  final int? place;

  /// Running session total.
  final int score;
  final bool showBacks;

  @override
  Widget build(BuildContext context) {
    final badge = place != null
        ? _Badge(text: ordinal(place!), color: const Color(0xFFFFC107))
        : passed
        ? const _Badge(text: 'Pass', color: Colors.blueGrey)
        : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTurn ? const Color(0xFFFFC107) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isBot ? Colors.teal : Colors.indigo,
                child: Icon(
                  isBot ? Icons.smart_toy : Icons.person,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 90),
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showBacks && cardCount > 0) ...[
                const CardBack(width: 16),
                const SizedBox(width: 4),
              ],
              Text(
                '$cardCount',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.star, size: 12, color: Color(0xFFFFC107)),
              const SizedBox(width: 2),
              Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (badge != null) ...[const SizedBox(width: 6), badge],
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String ordinal(int n) => switch (n) {
  1 => '1st',
  2 => '2nd',
  3 => '3rd',
  _ => '${n}th',
};
