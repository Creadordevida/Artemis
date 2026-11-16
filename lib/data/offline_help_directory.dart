import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'help_resource.dart';

/// Reads bundled, offline-first resources. Invalid packages are rejected
/// atomically so the UI never mixes unverified or partial data into results.
class OfflineHelpDirectory {
  OfflineHelpDirectory._(this.resources, this.region, this.builtAt);
  final List<HelpResource> resources;
  final String region;
  final DateTime builtAt;

  static Future<OfflineHelpDirectory> fromAsset(
    String assetPath,
  ) async {
    final text = await rootBundle.loadString(assetPath);
    return parse(text);
  }

  static OfflineHelpDirectory parse(String data) {
    final decoded = jsonDecode(data);
    if (decoded is! Map<String, dynamic> ||
        decoded['schema'] != 1 ||
        decoded['region'] is! String ||
        decoded['builtAt'] is! String ||
        decoded['resources'] is! List) {
      throw const FormatException('Unsupported territorial data package');
    }
    final date = DateTime.tryParse(decoded['builtAt'] as String);
    if (date == null) throw const FormatException('Invalid package date');
    final seen = <String>{};
    final resources = <HelpResource>[];
    for (final item in decoded['resources'] as List) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid resource record');
      }
      final resource = HelpResource.fromJson(item);
      if (!seen.add(resource.id)) {
        throw const FormatException('Duplicate resource ID');
      }
      resources.add(resource);
    }
    return OfflineHelpDirectory._(
      List.unmodifiable(resources), decoded['region'] as String, date,
    );
  }

  List<HelpResource> byKind(HelpKind kind) =>
      List.unmodifiable(resources.where((resource) => resource.kind == kind));
}
