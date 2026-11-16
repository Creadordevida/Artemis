import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:artemis/data/navarra_map_style.dart';

void main() {
  test('Offline basemap references only an on-device MBTiles file', () {
    final style = jsonDecode(navarraMapStyle('/data/user/0/artemis/navarra.mbtiles'))
        as Map<String, dynamic>;
    final sources = style['sources'] as Map<String, dynamic>;
    final local = sources['navarra'] as Map<String, dynamic>;
    expect(local['url'], 'mbtiles:///data/user/0/artemis/navarra.mbtiles');
    expect(local['type'], 'vector');
    expect(local['attribution'], contains('OpenStreetMap'));
    final serialized = jsonEncode(style);
    expect(serialized, isNot(contains('https://')));
    expect(serialized, isNot(contains('http://')));
  });
}
