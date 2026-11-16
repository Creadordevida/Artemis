import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artemis/navarra_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Carga recursos geolocalizados y filtra sanitarios solo públicos', () async {
    final resources = await loadMapResourceCollection();
    final police = resources.points.where((p) => p.category != 'centro_sanitario');
    final health = resources.points.where((p) => p.category == 'centro_sanitario');
    expect(police.length, 63);
    expect(health.length, 336);
    expect(resources.points.length, 399);
    expect(resources.directory.where((x) => x.category == 'centro_sanitario').length, 304);
    expect(resources.points.every((p) =>
        p.hasApproximatePosition && p.name.isNotEmpty && p.source.startsWith('https://')),
        isTrue);
    final raw = jsonDecode(
      await rootBundle.loadString('assets/offline/navarra_sns_geo.json'),
    ) as List<dynamic>;
    expect(raw.every((item) {
      final data = item as Map<String, dynamic>;
      return data['public_ownership_verified'] == true &&
          data['emergency_service_confirmed'] == false &&
          data['location_quality'] == 'official_idena_facility_point_not_entrance';
    }), isTrue);
  });
}
