import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre/maplibre.dart';
import 'package:path_provider/path_provider.dart';
import '../data/navarra_map_style.dart';

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
          style: MapStyle.json(navarraMapStyle(snapshot.data!)),
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
