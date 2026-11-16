import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

/// Offline fallback: road AXES from IDENA only. This is not a complete street
/// network or a routable map. No service or network connections are needed.
Future<List<Polyline>> loadOfflineNavarraRoads() async {
  final raw = await rootBundle.loadString('assets/offline/navarra_road_lines.json');
  final decoded = await compute(_decodeRoads, raw);
  if (decoded.length < 1000) {
    throw StateError('Incomplete offline road package');
  }
  return decoded.map((line) => Polyline(
    points: line.map((coords) => LatLng(coords[0], coords[1])).toList(growable: false),
    strokeWidth: 2,
    color: const Color(0xFF6C8491),
  )).toList(growable: false);
}

List<List<List<double>>> _decodeRoads(String source) {
  final parsed = jsonDecode(source) as List<dynamic>;
  return parsed.map((rawLine) {
    final coords = (rawLine as List<dynamic>).map((rawPoint) {
      final pair = rawPoint as List<dynamic>;
      if (pair.length != 2) throw FormatException('Malformed road vertex');
      final lat = (pair[0] as num).toDouble();
      final lon = (pair[1] as num).toDouble();
      if (lat < 41.6 || lat > 43.5 || lon < -2.8 || lon > -0.55) {
        throw FormatException('Road coordinate outside Navarra bounds');
      }
      return <double>[lat, lon];
    }).toList(growable: false);
    if (coords.length < 2) throw FormatException('Road with fewer than 2 vertices');
    return coords;
  }).toList(growable: false);
}
