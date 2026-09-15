import 'package:flutter_test/flutter_test.dart';

import 'package:toto/main.dart';

void main() {
  testWidgets('home page renders attendance dashboard and history page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('ToTo Capital'), findsOneWidget);
    expect(find.text('Hello, Vibol'), findsOneWidget);
    expect(find.text('ALIGN QR CODE'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.text('SCAN'), findsOneWidget);
    expect(find.textContaining('LIVE LOCATION:'), findsOneWidget);

    await tester.tap(find.text('HISTORY'));
    await tester.pumpAndSettle();

    expect(find.text('WORK HISTORY'), findsOneWidget);
    expect(find.text('Weekly Summary'), findsOneWidget);
    expect(find.text('Attendance Log'), findsOneWidget);
    expect(find.text('Clocked In'), findsWidgets);
  });
}
