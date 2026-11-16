import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artemis/flashlight_control.dart';

class FakeFlashHardware implements FlashHardware {
  FakeFlashHardware({required this.hasFlash, this.fails = false});
  final bool hasFlash;
  final bool fails;
  int enabledCalls = 0;
  int disabledCalls = 0;
  @override
  Future<bool> available() async => hasFlash;

  @override
  Future<void> enable() async {
    if (fails) throw StateError('camera unavailable');
    enabledCalls += 1;
  }

  @override
  Future<void> disable() async {
    disabledCalls += 1;
  }
}

void main() {
  testWidgets('Una pulsación enciende y otra apaga el flash', (tester) async {
    final fake = FakeFlashHardware(hasFlash: true);
    await tester.pumpWidget(MaterialApp(home: Scaffold(appBar: AppBar(actions: [
      FlashlightAction(hardware: fake),
    ]))));
    expect(find.byTooltip('Encender linterna'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('flashlight-action')));
    await tester.pumpAndSettle();
    expect(fake.enabledCalls, 1);
    expect(find.byTooltip('Apagar linterna'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('flashlight-action')));
    await tester.pumpAndSettle();
    expect(fake.disabledCalls, 1);
    expect(find.byTooltip('Encender linterna'), findsOneWidget);
  });

  testWidgets('Si no hay flash usa luz de pantalla con salida visible', (tester) async {
    final fake = FakeFlashHardware(hasFlash: false);
    await tester.pumpWidget(MaterialApp(home: Scaffold(appBar: AppBar(actions: [
      FlashlightAction(hardware: fake),
    ]))));
    await tester.tap(find.byKey(const ValueKey('flashlight-action')));
    await tester.pumpAndSettle();
    expect(find.text('Luz de pantalla · no usa el flash'), findsOneWidget);
    expect(fake.enabledCalls, 0);
    await tester.tap(find.byKey(const ValueKey('close-screen-lantern')));
    await tester.pumpAndSettle();
    expect(find.text('Luz de pantalla · no usa el flash'), findsNothing);
  });

  testWidgets('Si falla la cámara utiliza alternativa sin bloquear', (tester) async {
    final fake = FakeFlashHardware(hasFlash: true, fails: true);
    await tester.pumpWidget(MaterialApp(home: Scaffold(appBar: AppBar(actions: [
      FlashlightAction(hardware: fake),
    ]))));
    await tester.tap(find.byKey(const ValueKey('flashlight-action')));
    await tester.pumpAndSettle();
    expect(find.text('Luz de pantalla · no usa el flash'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('close-screen-lantern')));
    await tester.pumpAndSettle();
  });
}
