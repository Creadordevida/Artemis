import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import 'offline_resources.dart';
import 'offline_roads.dart';
import 'offline_streets.dart';

class MapResourceCollection {
  const MapResourceCollection({required this.directory, required this.points});
  final List<OfflinePlace> directory;
  final List<OfflinePlace> points;
}

/// Official public-health GIS points are independent from the local CSV
/// directory. Do not automatically claim an identity match without review.
Future<MapResourceCollection> loadMapResourceCollection() async {
  final directory = await loadOfflinePlaces();
  final contents = await rootBundle.loadString('assets/offline/navarra_sns_geo.json');
  final gis = jsonDecode(contents) as List<dynamic>;
  final verifiedHealth = gis
      .where((item) {
        final row = item as Map<String, dynamic>;
        return row['category'] == 'centro_sanitario' &&
            row['public_ownership_verified'] == true &&
            row['location_quality'] == 'official_idena_facility_point_not_entrance';
      })
      .map((raw) => OfflinePlace.fromJson(raw as Map<String, dynamic>))
      .where((place) => place.hasApproximatePosition)
      .toList(growable: false);
  final police = directory
      .where((place) => place.category != 'centro_sanitario' && place.hasApproximatePosition)
      .toList(growable: false);
  return MapResourceCollection(
    directory: directory,
    points: [...police, ...verifiedHealth],
  );
}

/// Map backgrounds require data connection, but pins and resource details
/// are loaded from the bundled, verified-public directory, without network.
/// Never infer a hospital entrance, business hours or walking route from
/// a postal address or point geometry.
class NavarraMapPage extends StatefulWidget {
  const NavarraMapPage({
    super.key,
    required this.onDial,
    this.currentLatitude,
    this.currentLongitude,
  });

  final Future<void> Function(String) onDial;
  final double? currentLatitude;
  final double? currentLongitude;

  @override
  State<NavarraMapPage> createState() => _NavarraMapPageState();
}

class _NavarraMapPageState extends State<NavarraMapPage> {
  final MapController controller = MapController();
  late final Future<MapResourceCollection> _resources = loadMapResourceCollection();
  bool tileError = false;
  bool offlineMode = false;
  late final Future<List<Polyline>> _offlineRoads = loadOfflineNavarraRoads();
  late final Future<OfflineStreetPaths> _streetPaths = loadOfficialStreetPaths();
  String filter = 'all';

  LatLng get startPoint =>
      widget.currentLatitude != null && widget.currentLongitude != null
          ? LatLng(widget.currentLatitude!, widget.currentLongitude!)
          : const LatLng(42.8125, -1.6458);

  void _showPlace(OfflinePlace item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(item.categoryLabel),
              if (item.municipality.isNotEmpty) Text(item.municipality),
              if (item.address.isNotEmpty) Text(item.address),
              const SizedBox(height: 10),
              const Text(
                'La posición es aproximada: no está verificada como entrada accesible. Horarios y atención de urgencias sin confirmar.',
              ),
              const SizedBox(height: 9),
              const Text(
                'Origen: directorio público de Navarra guardado en Artemis.',
                style: TextStyle(fontSize: 12, color: Color(0xFF526170)),
              ),
              const SizedBox(height: 12),
              if (item.phone != null && item.phone!.trim().isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => widget.onDial(item.phone!.trim()),
                  icon: const Icon(Icons.phone),
                  label: Text('Llamar: ${item.phone}'),
                ),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver al mapa'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Navarra'),
        actions: [
          IconButton(
            tooltip: 'Centrar mapa',
            icon: const Icon(Icons.my_location),
            onPressed: () => controller.move(startPoint, 12),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<MapResourceCollection>(
          future: _resources,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              if (snapshot.hasError) {
                return _MapNoData(onDial: widget.onDial);
              }
              return const Center(child: CircularProgressIndicator());
            }
            final directory = snapshot.data!.directory;
            final points = snapshot.data!.points;
            // Official SNS GIS points complement the distinct CSV directory.
            final mapped = points.where((place) =>
                place.hasApproximatePosition &&
                (filter == 'all' ||
                    (filter == 'health' && place.category == 'centro_sanitario') ||
                    (filter == 'police' && place.category == 'policia_foral') ||
                    (filter == 'guard' && place.category == 'guardia_civil'))).toList();
            final healthDirectoryCount = directory.where((place) => place.category == 'centro_sanitario').length;
            final officialHealthPoints = points.where((place) => place.category == 'centro_sanitario').length;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offlineMode
                          ? 'Mapa básico OFFLINE · ejes oficiales de carretera'
                          : 'Mapa ONLINE · recursos públicos guardados offline',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, icon: Icon(Icons.wifi),
                            label: Text('Online')),
                          ButtonSegment(value: true, icon: Icon(Icons.wifi_off),
                            label: Text('Sin Internet')),
                        ],
                        selected: {offlineMode},
                        onSelectionChanged: (selection) {
                          setState(() => offlineMode = selection.first);
                        },
                      ),
                      if (offlineMode)
                        const Text(
                          'Cartografía local de carreteras; el detalle adicional de calles y caminos está sujeto a disponibilidad del paquete oficial. No calcula rutas ni garantiza recorridos peatonales.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF526170)),
                        ),
                      const SizedBox(height: 5),
                      Text(
                        '${mapped.length} puntos públicos representados (incluye '
                        '$officialHealthPoints ubicaciones sanitarias oficiales). '
                        'El directorio tiene $healthDirectoryCount fichas sanitarias: '
                        'su correspondencia individual sigue pendiente de revisión.',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (tileError && !offlineMode)
                        const Text(
                          'No se pudieron cargar algunas calles. Los puntos y el directorio siguen disponibles sin Internet.',
                          style: TextStyle(color: Color(0xFF9E3540), fontSize: 12),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 7,
                        children: [
                          ChoiceChip(
                            label: const Text('Todos'),
                            selected: filter == 'all',
                            onSelected: (_) => setState(() => filter = 'all'),
                          ),
                          ChoiceChip(
                            label: const Text('Salud pública'),
                            selected: filter == 'health',
                            onSelected: (_) => setState(() => filter = 'health'),
                          ),
                          ChoiceChip(
                            label: const Text('Policía Foral'),
                            selected: filter == 'police',
                            onSelected: (_) => setState(() => filter = 'police'),
                          ),
                          ChoiceChip(
                            label: const Text('Guardia Civil'),
                            selected: filter == 'guard',
                            onSelected: (_) => setState(() => filter = 'guard'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: controller,
                        options: MapOptions(
                          initialCenter: startPoint,
                          initialZoom: widget.currentLatitude == null ? 9.8 : 12,
                          minZoom: 6,
                          maxZoom: 18,
                          backgroundColor: const Color(0xFFE8EDF0),
                        ),
                        children: [
                          if (offlineMode)
                            FutureBuilder<List<Polyline>>(
                              future: _offlineRoads,
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return const ColoredBox(
                                    color: Color(0xFFE8EDF0),
                                    child: Center(child: Text(
                                      'No se ha podido abrir el mapa local. Los puntos públicos y teléfonos siguen disponibles.',
                                      textAlign: TextAlign.center,
                                    )),
                                  );
                                }
                                if (!snapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                return PolylineLayer(polylines: snapshot.data!);
                              },
                            ),
                          // Official city streets and paths are optional until
                          // a complete, validated asset is bundled. Failure must
                          // never blank the existing offline road overview.
                          if (offlineMode)
                            Builder(builder: (mapContext) {
                              // Do not render tens of thousands of small
                              // features when showing the whole region.
                              if (MapCamera.of(mapContext).zoom < 11) {
                                return const SizedBox.shrink();
                              }
                              return FutureBuilder<OfflineStreetPaths>(
                                future: _streetPaths,
                                builder: (context, data) => PolylineLayer<Object>(
                                  polylines: data.data?.streets ?? const <Polyline<Object>>[],
                                ),
                              );
                            }),
                          if (offlineMode)
                            Builder(builder: (mapContext) {
                              if (MapCamera.of(mapContext).zoom < 12) {
                                return const SizedBox.shrink();
                              }
                              return FutureBuilder<OfflineStreetPaths>(
                                future: _streetPaths,
                                builder: (context, data) => PolylineLayer<Object>(
                                  polylines: data.data?.paths ?? const <Polyline<Object>>[],
                                ),
                              );
                            }),
                          if (!offlineMode)
                            TileLayer(
                            // Online tiles ONLY; no bulk or offline OSM tile scraping.
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'org.artemis.help',
                            maxNativeZoom: 19,
                            errorTileCallback: (_, __, ___) {
                              if (tileError || !mounted) return;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() => tileError = true);
                              });
                            },
                          ),
                          // Street names: only at detailed zoom and only inside
                          // the visible viewport, with a strict 70-label cap.
                          if (offlineMode)
                            Builder(builder: (mapContext) {
                              final camera = MapCamera.of(mapContext);
                              if (camera.zoom < 15) {
                                return const SizedBox.shrink();
                              }
                              return FutureBuilder<OfflineStreetPaths>(
                                future: _streetPaths,
                                builder: (context, data) {
                                  final labels = data.data?.labels ?? const <OfflineStreetLabel>[];
                                  final visible = labels
                                      .where((label) => camera.visibleBounds.contains(label.point))
                                      .take(70);
                                  return MarkerLayer(
                                    markers: [
                                      for (final label in visible)
                                        Marker(
                                          point: label.point,
                                          width: 150,
                                          height: 22,
                                          child: Center(
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: const Color(0xCCFFFFFF),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                                child: Text(label.text,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Color(0xFF273944),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  )),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              );
                            }),
                          MarkerClusterLayerWidget(
                            options: MarkerClusterLayerOptions(
                              maxClusterRadius: 48,
                              size: const Size(44, 44),
                              padding: const EdgeInsets.all(36),
                              markers: [
                              ...mapped.map((place) => Marker(
                                width: 45,
                                height: 45,
                                point: LatLng(place.latitude!, place.longitude!),
                                child: IconButton(
                                  tooltip: '${place.categoryLabel}: ${place.name}',
                                  icon: Icon(
                                    place.category == 'centro_sanitario'
                                        ? Icons.local_hospital_outlined
                                        : Icons.shield_outlined,
                                    color: place.category == 'centro_sanitario'
                                        ? const Color(0xFF155C63)
                                        : place.category == 'policia_foral'
                                            ? const Color(0xFF183A68)
                                            : const Color(0xFF7B3B49),
                                    size: 27,
                                  ),
                                  onPressed: () => _showPlace(place),
                                ),
                              )),
                            ],
                            builder: (context, clusterMarkers) => DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFF14283B),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  '${clusterMarkers.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            ),
                          ),
                          // The location marker must never be merged into a
                          // cluster of public institutions.
                          if (widget.currentLatitude != null &&
                              widget.currentLongitude != null)
                            MarkerLayer(
                              markers: [
                              if (widget.currentLatitude != null && widget.currentLongitude != null)
                                Marker(
                                  width: 45,
                                  height: 45,
                                  point: LatLng(widget.currentLatitude!, widget.currentLongitude!),
                                  child: const Icon(Icons.my_location,
                                    size: 27, color: Color(0xFF2567C5)),
                                ),
                              ],
                            ),
                          // Always visible attribution; no hiding in a popup.
                          Align(
                            alignment: Alignment.bottomRight,
                            child: ColoredBox(
                              color: const Color(0xEFFFFFFF),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                child: Text(
                                  offlineMode
                                    ? '© SITNA / Gobierno de Navarra · CC BY 4.0'
                                    : '© OpenStreetMap contributors',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF203040)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: FilledButton.tonalIcon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => OfflineResourcesPage(
                                initialCategory: 'all',
                                onDial: widget.onDial,
                                latitude: widget.currentLatitude,
                                longitude: widget.currentLongitude,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.list_alt),
                          label: const Text('Ver directorio'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 7, 14, 11),
          child: FilledButton.icon(
            onPressed: () => widget.onDial('112'),
            icon: const Icon(Icons.phone),
            label: const Text('Emergencias 112'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFAA3945),
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapNoData extends StatelessWidget {
  const _MapNoData({required this.onDial});
  final Future<void> Function(String) onDial;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('No podemos abrir ahora el directorio de recursos.'),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => onDial('112'),
          icon: const Icon(Icons.phone),
          label: const Text('Emergencias 112'),
        ),
      ]),
    ),
  );
}
