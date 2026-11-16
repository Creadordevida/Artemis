import 'package:flutter_test/flutter_test.dart';
import 'package:artemis/offline_roads.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Navarra road overview is bundled and works without Internet', () async {
    final lines = await loadOfflineNavarraRoads();
    expect(lines.length, 17479);
    expect(lines.every((line) => line.points.length >= 2), isTrue);
    expect(lines.every((line) => line.points.every((p) =>
        p.latitude >= 41.6 && p.latitude <= 43.5 &&
        p.longitude >= -2.8 && p.longitude <= -0.55)), isTrue);
  });
}
