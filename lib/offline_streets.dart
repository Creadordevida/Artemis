import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

/// Official IDENA street/path vector dataset, transformed at build time.
/// Unlike a complete pedestrian graph, these lines do NOT establish
/// safe walking access or crossing availability.
class OfflineStreetLabel {
  const OfflineStreetLabel({required this.text, required this.point});
  final String text;
  final LatLng point;
}

class OfflineStreetPaths {
  const OfflineStreetPaths({
    required this.streets,
    required this.paths,
    required this.labels,
  });

  final List<Polyline<Object>> streets;
  final List<Polyline<Object>> paths;
  final List<OfflineStreetLabel> labels;
  int get labelCount => labels.length;
}

Future<OfflineStreetPaths> loadOfficialStreetPaths() async {
  final encoded = await rootBundle.loadString(
    'assets/offline/navarra_streets_paths.json',
  );
  final parsed = await compute(parseOfficialStreetPaths, encoded);
  if (parsed.streets.length < 1000 || parsed.paths.length < 1000) {
    throw StateError('El paquete de calles y caminos de Navarra está incompleto.');
  }
  return parsed;
}

/// Navarra-wide cadastral axes and names, stored locally. These lines
/// describe mapped streets, not pedestrian access or routes.
Future<OfflineStreetPaths> loadCadastralStreetPaths() async {
  final source = await rootBundle.loadString(
    'assets/offline/navarra_cadastral_streets.json',
  );
  final data = await compute(parseOfficialStreetPaths, source);
  if (data.streets.length < 20000 || data.labelCount < 5000) {
    throw StateError('El callejero catastral local está incompleto.');
  }
  return data;
}

/// Pure decoding function; may execute in a background isolate.
OfflineStreetPaths parseOfficialStreetPaths(String encoded) {
  final obj = jsonDecode(encoded) as Map<String, dynamic>;
  final roads = _readLines(obj['streets'], const Color(0xFF637D93), 2.1);
  final paths = _readLines(obj['paths'], const Color(0xFF9B8A6D), 1.35);
  final rawLabels = obj['labels'] as List<dynamic>;
  if (rawLabels.length > 60000) {
    throw const FormatException('Abnormal street-label volume');
  }
  final labels = rawLabels.map((raw) {
    final item = raw as Map<String, dynamic>;
    final text = (item['text'] as String).trim();
    final lat = (item['lat'] as num).toDouble();
    final lon = (item['lon'] as num).toDouble();
    if (text.isEmpty || text.length > 100 ||
        !lat.isFinite || !lon.isFinite ||
        lat < 41.6 || lat > 43.5 || lon < -2.8 || lon > -0.55) {
      throw const FormatException('Invalid street label');
    }
    return OfflineStreetLabel(text: text, point: LatLng(lat, lon));
  }).toList(growable: false);
  return OfflineStreetPaths(
    streets: roads,
    paths: paths,
    labels: labels,
  );
}

List<Polyline<Object>> _readLines(dynamic raw, Color color, double width) {
  final lines = raw as List<dynamic>;
  if (lines.length > 130000) {
    throw const FormatException('Abnormal vector line count');
  }
  return lines.map((item) {
    final line = item as List<dynamic>;
    if (line.length < 2) {
      throw const FormatException('Too-short line');
    }
    final coords = line.map((entry) {
      final point = entry as List<dynamic>;
      if (point.length != 2) {
        throw const FormatException('Invalid coordinate pair');
      }
      final lat = (point[0] as num).toDouble();
      final lon = (point[1] as num).toDouble();
      if (!lat.isFinite || !lon.isFinite ||
          lat < 41.6 || lat > 43.5 || lon < -2.8 || lon > -0.55) {
        throw const FormatException('Off-region vector coordinate');
      }
      return LatLng(lat, lon);
    }).toList(growable: false);
    return Polyline<Object>(points: coords, strokeWidth: width, color: color);
  }).toList(growable: false);
}

/// Return only lines whose geometry bounds intersect the visible map.
/// This avoids sending tens of thousands of off-screen polylines to the
/// renderer. A crossing segment is retained even when neither end is inside.
List<Polyline<Object>> visibleOfflineLines(
  List<Polyline<Object>> source,
  LatLngBounds visibleBounds,
) {
  final result = <Polyline<Object>>[];
  final west = visibleBounds.west;
  final east = visibleBounds.east;
  final south = visibleBounds.south;
  final north = visibleBounds.north;

  for (final line in source) {
    double minLat = 91, maxLat = -91, minLon = 181, maxLon = -181;
    for (final point in line.points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }
    if (maxLat >= south && minLat <= north &&
        maxLon >= west && minLon <= east) {
      result.add(line);
    }
  }
  return result;
}
