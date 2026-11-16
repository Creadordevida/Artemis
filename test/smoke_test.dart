import 'package:flutter_test/flutter_test.dart';
import 'package:artemis/main.dart';

void main() {
  testWidgets('Muestra ayuda básica sin depender de una respuesta GPS',
      (tester) async {
    await tester.pumpWidget(const ArtemisApp());
    expect(find.text('ARTEMIS'), findsOneWidget);
    expect(find.text('Emergencias 112'), findsOneWidget);
    expect(find.text('No sé qué hacer'), findsOneWidget);
  });
}
