/// The on-device, validated information contract for Artemis.
import 'dart:math' as math;

enum HelpKind { emergency, health, police, pharmacy, youthSupport, other }

class HelpResource {
  const HelpResource({
    required this.id,
    required this.name,
    required this.kind,
    required this.source,
    required this.verifiedAt,
    this.latitude,
    this.longitude,
    this.phone,
    this.address,
    this.hours,
  });

  final String id;
  final String name;
  final HelpKind kind;
  final String source;
  final DateTime verifiedAt;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? address;
  final String? hours;

  bool get hasLocation => latitude != null && longitude != null;

  static HelpResource fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final kind = json['kind'];
    final source = json['source'];
    final verifiedAt = json['verifiedAt'];
    if (id is! String || id.trim().isEmpty ||
        name is! String || name.trim().isEmpty ||
        kind is! String || source is! String || source.trim().isEmpty ||
        verifiedAt is! String) {
      throw const FormatException('Missing resource provenance or identity');
    }
    final parsedKind = HelpKind.values.where((k) => k.name == kind);
    if (parsedKind.isEmpty) throw const FormatException('Unknown help kind');
    final time = DateTime.tryParse(verifiedAt);
    if (time == null) throw const FormatException('Invalid verifiedAt');
    final lat = (json['latitude'] as num?)?.toDouble();
    final lon = (json['longitude'] as num?)?.toDouble();
    if ((lat == null) != (lon == null)) {
      throw const FormatException('Coordinates must be a pair');
    }
    if (lat != null && (lat.abs() > 90 || lon!.abs() > 180)) {
      throw const FormatException('Coordinates outside valid range');
    }
    return HelpResource(
      id: id, name: name, kind: parsedKind.first,
      source: source, verifiedAt: time,
      latitude: lat, longitude: lon,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      hours: json['hours'] as String?,
    );
  }

  /// Only a geographical hint, never a promise of travel distance or access.
  /// Haversine distance in meters; routing must use a validated walkable graph.
  double? straightLineMeters(double lat, double lon) {
    if (!hasLocation) return null;
    const r = 6371000.0;
    final p1 = latitude! * 0.017453292519943295;
    final p2 = lat * 0.017453292519943295;
    final dPhi = (lat - latitude!) * 0.017453292519943295;
    final dLam = (lon - longitude!) * 0.017453292519943295;
    final a = _sinHalf(dPhi) * _sinHalf(dPhi) +
        _cos(p1) * _cos(p2) * _sinHalf(dLam) * _sinHalf(dLam);
    return 2 * r * _asinSqrt(a);
  }
}

// dart:math kept isolated to simplify tests.
double _sinHalf(double x) => math.sin(x / 2);
double _cos(double x) => math.cos(x);
double _asinSqrt(double x) => math.asin(math.sqrt(x.clamp(0.0, 1.0)));
