import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artemis/main.dart';

void main() {
  testWidgets('El acceso a 112 permanece visible aunque el GPS no responda',
      (tester) async {
    await tester.pumpWidget(const ArtemisApp());
    expect(find.text('ARTEMIS'), findsOneWidget);
    expect(find.text('Emergencias 112'), findsOneWidget);
    expect(find.text('Tu ubicación'), findsOneWidget);

    // Un botón fijo debe permanecer visible mientras desplazamos el contenido.
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    expect(find.text('Emergencias 112'), findsOneWidget);
    expect(find.byIcon(Icons.call), findsWidgets);
  });
}
