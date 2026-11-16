import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
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
}
