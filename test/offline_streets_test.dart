import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:artemis/offline_streets.dart';

void main() {
  test('Decodifica trazados oficiales sin depender de Internet', () {
    final payload = jsonEncode({
      'streets': [[[42.816, -1.641], [42.817, -1.642]]],
      'paths': [[[42.82, -1.63], [42.83, -1.62]]],
      'labels': [{'text': 'Ejemplo', 'lat': 42.816, 'lon': -1.641}],
    });
    final data = parseOfficialStreetPaths(payload);
    expect(data.streets.length, 1);
    expect(data.paths.length, 1);
    expect(data.labelCount, 1);
  });

  test('Rechaza geometría fuera de Navarra', () {
    final payload = jsonEncode({
      'streets': [[[40.0, -3.0], [40.1, -3.1]]],
      'paths': [[[42.82, -1.63], [42.83, -1.62]]],
      'labels': [],
    });
    expect(() => parseOfficialStreetPaths(payload), throwsFormatException);
  });

  test('Rechaza polilíneas incompletas', () {
    final payload = jsonEncode({
      'streets': [[[42.816, -1.641]]],
      'paths': [[[42.82, -1.63], [42.83, -1.62]]],
      'labels': [],
    });
    expect(() => parseOfficialStreetPaths(payload), throwsFormatException);
  });
  test('Carga íntegramente el paquete regional oficial sin Internet', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final data = await loadOfficialStreetPaths();
    expect(data.streets.length, 7749);
    expect(data.paths.length, 12683);
    expect(data.labelCount, 6274);
  });

  test('Callejero catastral abarca Elizondo/Baztan y se carga sin red',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final pack = await loadCadastralStreetPaths();
    expect(pack.streets.length, 64893);
    expect(pack.labelCount, 21472);
    expect(pack.paths, isEmpty);

    // El paquete anterior 1:1.000 no tenía calles en esta ventana.
    final coversElizondo = pack.streets.any((road) => road.points.any(
      (point) =>
          (point.latitude - 43.145).abs() < 0.03 &&
          (point.longitude + 1.520).abs() < 0.03,
    ));
    expect(coversElizondo, isTrue);
  });

  test('Solo dibuja trazados de la región visible', () {
    final parsed = parseOfficialStreetPaths(jsonEncode({
      'streets': [
        [[42.81, -1.64], [42.82, -1.65]],
        [[42.46, -1.60], [42.47, -1.61]],
        [[42.80, -1.70], [42.80, -1.60]],
      ],
      'paths': [],
      'labels': [],
    }));
    final viewport = LatLngBounds(
      const LatLng(42.79, -1.66), const LatLng(42.84, -1.62));
    final visible = visibleOfflineLines(parsed.streets, viewport);
    expect(visible.length, 2);
    // A line that crosses the screen must remain even if neither
    // endpoint falls inside the viewport.
    expect(visible.last.points.last.longitude, closeTo(-1.60, 0.001));
  });

}
