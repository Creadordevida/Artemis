import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

/// Official IDENA street/path vector dataset, transformed at build time.
/// Unlike a complete pedestrian graph, these lines do NOT establish
/// safe walking access or crossing availability.
class OfflineStreetPaths {
  const OfflineStreetPaths({
    required this.streets,
    required this.paths,
    required this.labelCount,
  });

  final List<Polyline> streets;
  final List<Polyline> paths;
  final int labelCount;
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

/// Pure decoding function; may execute in a background isolate.
OfflineStreetPaths parseOfficialStreetPaths(String encoded) {
  final obj = jsonDecode(encoded) as Map<String, dynamic>;
  final roads = _readLines(obj['streets'], const Color(0xFF637D93), 2.1);
  final paths = _readLines(obj['paths'], const Color(0xFF9B8A6D), 1.35);
  final labels = obj['labels'] as List<dynamic>;
  if (labels.length > 10000) {
    throw const FormatException('Abnormal street-label volume');
  }
  return OfflineStreetPaths(
    streets: roads,
    paths: paths,
    labelCount: labels.length,
  );
}

List<Polyline> _readLines(dynamic raw, Color color, double width) {
  final lines = raw as List<dynamic>;
  if (lines.length > 50000) {
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
    return Polyline(points: coords, strokeWidth: width, color: color);
  }).toList(growable: false);
}
