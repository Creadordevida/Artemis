import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre/maplibre.dart';
import 'package:path_provider/path_provider.dart';

/// Loads an embedded regional vector map. Never falls back to web tiles.
/// A 112 action is always available on the parent screen during preparation.
class NavarraOfflineMap extends StatefulWidget {
  const NavarraOfflineMap({super.key, this.latitude, this.longitude, this.isCurrent = false});
  final double? latitude;
  final double? longitude;
  final bool isCurrent;

  @override
  State<NavarraOfflineMap> createState() => _NavarraOfflineMapState();
}

class _NavarraOfflineMapState extends State<NavarraOfflineMap> {
  late final Future<String> _tilesPath = _prepareTiles();

  Future<String> _prepareTiles() async {
    final directory = await getApplicationSupportDirectory();
    final path = '${directory.path}/navarra-shortbread-v1.mbtiles';
    final file = File(path);
    if (await file.exists() && await file.length() > 1000000) return path;
    final data = await rootBundle.load('assets/maps/navarra.mbtiles');
    final temp = File('$path.part');
    await temp.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    if (await temp.length() < 1000000) {
      await temp.delete();
      throw const FormatException('El archivo del mapa no está completo');
    }
    await temp.rename(path);
    return path;
  }

  String _style(String path) => jsonEncode({
    'version': 8,
    'name': 'Artemis Navarra local',
    'sources': {
      'navarra': {
        'type': 'vector',
        'url': 'mbtiles://$path',
        'attribution': '© OpenStreetMap contributors (ODbL) / Geofabrik',
      },
    },
    'layers': [
      {'id':'base','type':'background','paint':{'background-color':'#e8eee9'}},
      {'id':'land','type':'fill','source':'navarra','source-layer':'land','paint':{'fill-color':'#dce6d6'}},
      {'id':'water','type':'fill','source':'navarra','source-layer':'water_polygons','paint':{'fill-color':'#a7c8dc'}},
      {'id':'rivers','type':'line','source':'navarra','source-layer':'water_lines','paint':{'line-color':'#83b6cf','line-width':1.5}},
      {'id':'buildings','type':'fill','source':'navarra','source-layer':'buildings','minzoom':13,'paint':{'fill-color':'#d2d8d6'}},
      {'id':'streets-base','type':'line','source':'navarra','source-layer':'streets','paint':{'line-color':'#ced4d4','line-width':3}},
      {'id':'streets-top','type':'line','source':'navarra','source-layer':'streets','paint':{'line-color':'#ffffff','line-width':1.7}},
    ],
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _tilesPath,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('No hemos podido abrir el mapa guardado. Puedes volver y usar los teléfonos de ayuda.\n\n${snapshot.error}',
              textAlign: TextAlign.center),
        ));
      }
      if (!snapshot.hasData) {
        return const Center(child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('Preparando el mapa de Navarra guardado en el móvil. Puedes volver a la ayuda cuando quieras.',
              textAlign: TextAlign.center),
          ]),
        ));
      }
      final hasPosition = widget.latitude != null && widget.longitude != null;
      return MapLibreMap(
        options: MapOptions(
          style: MapStyle.json(_style(snapshot.data!)),
          initCamera: CameraUpdate.position(
            center: Geographic(
              lon: hasPosition ? widget.longitude! : -1.64,
              lat: hasPosition ? widget.latitude! : 42.75,
            ),
            zoom: hasPosition ? 13 : 8.3,
          ),
          minZoom: 6,
          maxZoom: 18,
        ),
        layers: [
          if (hasPosition)
            CircleLayer(
              points: [
                Feature(geometry: Point(Geographic(
                  lon: widget.longitude!, lat: widget.latitude!,
                ))),
              ],
              color: .literal(widget.isCurrent
                  ? const Color(0xFF3479E5) : const Color(0xFF7C8895)),
              radius: const .literal(9),
              strokeColor: const .literal(Colors.white),
              strokeWidth: const .literal(3),
            ),
        ],
      );
    },
  );
}
