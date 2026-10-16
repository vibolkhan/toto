import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:toto/engine/card.dart';
import 'package:toto/engine/combo.dart';
import 'package:toto/engine/instant_win.dart';
import 'package:toto/engine/rules.dart';

List<PlayingCard> cards(List<dynamic> raw) =>
    raw.map((e) => PlayingCard.parse(e as String)).toList();

void main() {
  final fixture =
      jsonDecode(File('test/fixtures/rules_cases.json').readAsStringSync())
          as Map<String, dynamic>;

  group('combo detection', () {
    for (final c in fixture['detect'] as List) {
      test('${c['cards']} -> ${c['type']}', () {
        expect(Combo.detect(cards(c['cards']))?.type.name, c['type']);
      });
    }
  });

  group('canBeat', () {
    for (final c in fixture['beats'] as List) {
      test('${c['prev']} vs ${c['next']} -> ${c['expected']}', () {
        final prev = c['prev'] == null ? null : Combo.detect(cards(c['prev']));
        final next = Combo.detect(cards(c['next']))!;
        expect(canBeat(prev, next), c['expected']);
      });
    }
  });

  group('instant win', () {
    for (final c in fixture['instantWin'] as List) {
      test('${c['expected']}', () {
        expect(detectInstantWin(cards(c['hand']))?.name, c['expected']);
      });
    }
  });

  group('chop points', () {
    for (final c in fixture['chops'] as List) {
      test('${c['prev']} chopped by ${c['next']} -> ${c['points']}', () {
        final prev = Combo.detect(cards(c['prev']))!;
        final next = Combo.detect(cards(c['next']))!;
        expect(chopPoints(prev, next), c['points']);
      });
    }
  });
}
