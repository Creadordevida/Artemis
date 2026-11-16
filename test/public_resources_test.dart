import 'package:flutter_test/flutter_test.dart';
import 'package:artemis/help_contacts.dart';
import 'package:artemis/offline_resources.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Solo aparecen dependencias policiales o centros sanitarios públicos verificados', () async {
    final places = await loadOfflinePlaces();
    expect(places, isNotEmpty);
    expect(places.any((p) => p.category == 'policia_foral'), isTrue);
    expect(places.any((p) => p.category == 'guardia_civil'), isTrue);
    for (final place in places) {
      expect(place.name.isNotEmpty, isTrue);
      expect(place.source.startsWith('https://'), isTrue);
      expect(place.type.contains('Clínicas dentales'), isFalse);
      if (place.category == 'centro_sanitario') {
        expect(place.type == 'Centros de salud' ||
            place.type == 'Consultorios de atención primaria', isTrue);
      }
    }
  });

  test('La ubicación no se inventa cuando faltan coordenadas', () async {
    final places = await loadOfflinePlaces();
    final publicPolice = places.firstWhere((p) => p.hasApproximatePosition);
    expect(publicPolice.distanceKm(null, null), isNull);
    expect(publicPolice.distanceKm(publicPolice.latitude, publicPolice.longitude),
        closeTo(0, 0.001));
  });

  test('Enfermera del Consejo Sanitario está en contactos offline', () {
    final nurse = helpContacts.singleWhere((c) => c.id == 'consejo_sanitario');
    expect(nurse.phone, '948290290');
    expect(nurse.name.toLowerCase().contains('enfermera'), isTrue);
    expect(nurse.source.contains('navarra.es'), isTrue);
  });
}
