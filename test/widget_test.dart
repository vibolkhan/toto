import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toto/game/game_controller.dart';
import 'package:toto/game/local_game_controller.dart';
import 'package:toto/main.dart';
import 'package:toto/ui/table_screen.dart';

void main() {
  testWidgets('home screen offers both modes', (tester) async {
    await tester.pumpWidget(const TienLenApp());
    expect(find.text('Tiến Lên'), findsOneWidget);
    expect(find.text('Play with bots'), findsOneWidget);
    expect(find.text('Play with friends'), findsOneWidget);
  });

  testWidgets('bot table renders 13 cards and bots take turns', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = LocalGameController(
      playerName: 'Me',
      random: Random(1),
      botDelay: const Duration(milliseconds: 10),
      dealDelay: Duration.zero,
    );
    await tester.pumpWidget(
      MaterialApp(home: TableScreen(controller: controller)),
    );
    expect(find.text('Me'), findsOneWidget);
    expect(find.text('Bot 1'), findsOneWidget);

    // Let bots play until it is the human's turn or the game ends.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    final s = controller.state;
    expect(s.isOver || s.turn == LocalGameController.humanSeat, isTrue);
  });

  testWidgets('bots wait for the deal before the first move', (tester) async {
    // Find a deal where a bot leads, so the first move is a bot's.
    var seed = 0;
    late LocalGameController controller;
    while (true) {
      controller = LocalGameController(
        playerName: 'Me',
        random: Random(seed++),
        botDelay: const Duration(milliseconds: 10),
      );
      final s = controller.state;
      if (s.turn != LocalGameController.humanSeat && !s.isOver) break;
      controller.dispose();
    }
    await tester.pumpWidget(
      MaterialApp(home: TableScreen(controller: controller)),
    );

    await tester.pump(dealDuration);
    expect(controller.state.lastAction, isNull);
    await tester.pump(const Duration(milliseconds: 20));
    expect(controller.state.lastAction, isNotNull);
  });
}
