import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artemis/help_contacts.dart';
import 'package:artemis/offline_resources.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Paquete offline contiene solamente entidades públicas verificadas', () async {
    final manifest = jsonDecode(
      await rootBundle.loadString('assets/offline/manifest.json'),
    ) as Map<String, dynamic>;
    expect(manifest['public_only_filter'], isTrue);
    expect(manifest['public_health_count'], greaterThan(100));

    final raw = jsonDecode(
      await rootBundle.loadString('assets/offline/navarra_frontline.json'),
    ) as List<dynamic>;
    for (final item in raw) {
      final resource = item as Map<String, dynamic>;
      if (resource['category'] == 'centro_sanitario') {
        expect(resource['public_ownership_verified'], isTrue);
        expect(
          (resource['ownership'] as String).toLowerCase().contains('privad'),
          isFalse,
        );
      }
    }

    final places = await loadOfflinePlaces();
    expect(places.where((p) => p.category == 'centro_sanitario').length, greaterThan(100));
    expect(places.where((p) => p.category == 'policia_foral').length, 9);
    expect(places.where((p) => p.category == 'guardia_civil').length, 54);
    for (final place in places) {
      expect(place.name.isNotEmpty, isTrue);
      expect(place.source.startsWith('https://'), isTrue);
      expect(place.type.contains('Clínicas dentales'), isFalse);
    }
  });

  test('No inventa coordenadas cuando el recurso solo tiene dirección', () async {
    final places = await loadOfflinePlaces();
    final police = places.firstWhere((p) => p.hasApproximatePosition);
    final health = places.firstWhere((p) => p.category == 'centro_sanitario');
    expect(police.distanceKm(null, null), isNull);
    expect(police.distanceKm(police.latitude, police.longitude), closeTo(0, 0.001));
    expect(health.hasApproximatePosition, isFalse);
    expect(health.distanceKm(police.latitude, police.longitude), isNull);
  });

  test('Enfermera pública de Navarra disponible en contactos offline', () {
    final nurse = helpContacts.singleWhere((c) => c.id == 'consejo_sanitario');
    expect(nurse.phone, '948290290');
    expect(nurse.name.toLowerCase().contains('enfermera'), isTrue);
    expect(nurse.source.contains('navarra.es'), isTrue);
  });
}
