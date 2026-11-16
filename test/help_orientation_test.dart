import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artemis/help_orientation.dart';

void main() {
  test('Cada situación tiene un paso concreto y una alternativa', () {
    for (final situation in HelpSituation.values) {
      final result = guidanceFor(situation);
      expect(result.title, isNotEmpty);
      expect(result.nextStep.length, greaterThan(30));
      expect(result.alternative.length, greaterThan(30));
      expect(result.nextStep.toLowerCase().contains('todo va a salir bien'), isFalse);
    }
  });

  testWidgets('La ayuda es offline y mantiene el 112 en la selección y el consejo',
      (tester) async {
    String? lastNumber;
    await tester.pumpWidget(MaterialApp(home: HelpOrientationPage(
      onDial: (number) async { lastNumber = number; },
    )));
    expect(find.text('Emergencias 112'), findsOneWidget);
    await tester.tap(find.text('Me encuentro mal'));
    await tester.pump();
    expect(find.text('Primer paso'), findsOneWidget);
    expect(find.text('Emergencias 112'), findsOneWidget);
    expect(find.textContaining('948290290'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('emergency-112')));
    expect(lastNumber, '112');
    await tester.tap(find.text('Elegir otra situación'));
    await tester.pump();
    expect(find.text('¿Qué te preocupa?'), findsOneWidget);
  });
}
