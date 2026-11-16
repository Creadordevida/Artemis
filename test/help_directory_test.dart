import 'package:flutter_test/flutter_test.dart';
import 'package:artemis/data/help_resource.dart';
import 'package:artemis/data/offline_help_directory.dart';

const valid = '''
{
  "schema": 1,
  "region": "ES-NC",
  "builtAt": "2026-11-16T12:00:00Z",
  "resources": [
    {
      "id": "es-112",
      "name": "Emergencias 112",
      "kind": "emergency",
      "source": "https://www.navarra.es/es/seguridad-y-emergencias/emergencias-112",
      "verifiedAt": "2026-11-16",
      "phone": "112"
    }
  ]
}
''';

void main() {
  test('Offline directory reads a verified phone without coordinates', () {
    final directory = OfflineHelpDirectory.parse(valid);
    expect(directory.region, 'ES-NC');
    expect(directory.byKind(HelpKind.emergency).single.phone, '112');
    expect(directory.resources.single.hasLocation, false);
  });
  test('Rejects a resource lacking provenance', () {
    final missingSource = valid.replaceAll(
      'https://www.navarra.es/es/seguridad-y-emergencias/emergencias-112', '');
    expect(() => OfflineHelpDirectory.parse(missingSource), throwsFormatException);
  });
  test('Rejects duplicate records', () {
    final directory = OfflineHelpDirectory.parse(valid);
    expect(directory.resources.length, 1);
    final duplicate = valid.replaceFirst('    }\n  ]', '    },\n    { "id":"es-112", "name":"Copy", "kind":"emergency", "source":"official", "verifiedAt":"2026-11-16" }\n  ]');
    expect(() => OfflineHelpDirectory.parse(duplicate), throwsFormatException);
  });
  test('Rejects geographic locations without coordinate pairs', () {
    expect(() => HelpResource.fromJson({
      'id':'x','name':'X','kind':'health','source':'official','verifiedAt':'2026-11-16','latitude':42.8
    }), throwsFormatException);
  });
}
