import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main.dart' show emergencyRed, navy;

class OfflinePlace {
  OfflinePlace.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String? ?? '',
        category = json['category'] as String? ?? '',
        address = json['address'] as String? ?? '',
        municipality = json['municipality'] as String? ?? '',
        phone = json['phone'] as String?,
        type = json['type'] as String? ?? '',
        source = json['source'] as String? ?? '',
        latitude = (json['lat'] as num?)?.toDouble(),
        longitude = (json['lon'] as num?)?.toDouble();

  final String name;
  final String category;
  final String address;
  final String municipality;
  final String? phone;
  final String type;
  final String source;
  final double? latitude;
  final double? longitude;

  bool get hasApproximatePosition => latitude != null && longitude != null;

  double? distanceKm(double? lat, double? lon) {
    if (lat == null || lon == null || !hasApproximatePosition) return null;
    const earthRadius = 6371.0088;
    double radians(double degrees) => degrees * math.pi / 180;
    final phi = radians(latitude! - lat);
    final lambda = radians(longitude! - lon);
    final a = math.pow(math.sin(phi / 2), 2) +
        math.cos(radians(lat)) * math.cos(radians(latitude!)) *
        math.pow(math.sin(lambda / 2), 2);
    return earthRadius * 2 * math.asin(math.min(1, math.sqrt(a)));
  }

  String get categoryLabel {
    if (category == 'policia_foral') return 'Policía Foral';
    if (category == 'guardia_civil') return 'Guardia Civil';
    return type.isNotEmpty ? type : 'Centro sanitario';
  }
}

Future<List<OfflinePlace>> loadOfflinePlaces() async {
  final source = await rootBundle.loadString('assets/offline/navarra_frontline.json');
  final entries = jsonDecode(source) as List<dynamic>;
  return entries.map((e) => OfflinePlace.fromJson(e as Map<String, dynamic>)).toList(growable: false);
}

class OfflineResourcesPage extends StatefulWidget {
  const OfflineResourcesPage({
    super.key,
    required this.initialCategory,
    required this.onDial,
    this.latitude,
    this.longitude,
  });

  final String initialCategory;
  final Future<void> Function(String number) onDial;
  // Current GPS fix only, never an unverified last-known location.
  final double? latitude;
  final double? longitude;

  @override
  State<OfflineResourcesPage> createState() => _OfflineResourcesPageState();
}

class _OfflineResourcesPageState extends State<OfflineResourcesPage> {
  late String category = widget.initialCategory;
  String query = '';
  late final Future<List<OfflinePlace>> places = loadOfflinePlaces();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda en Navarra')),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Recursos guardados en tu móvil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: navy)),
              const SizedBox(height: 6),
              const Text('Puedes consultar direcciones y teléfonos sin Internet. No tenemos horarios confirmados ni podemos asegurar atención de urgencias.'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Tipo de ayuda', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'centro_sanitario', child: Text('Salud')),
                  DropdownMenuItem(value: 'seguridad', child: Text('Policía y Guardia Civil')),
                  DropdownMenuItem(value: 'all', child: Text('Todos los recursos')),
                ],
                onChanged: (next) { if (next != null) setState(() => category = next); },
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar localidad, nombre o dirección',
                ),
                onChanged: (text) => setState(() => query = text.trim().toLowerCase()),
              ),
              if (widget.latitude == null)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('Sin ubicación actual: puedes buscar por localidad. No mostramos distancias inventadas.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF526170))),
                ),
            ]),
          ),
          Expanded(child: FutureBuilder<List<OfflinePlace>>(
            future: places,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _EmptyState(
                  message: 'No pudimos abrir el directorio guardado.',
                  detail: 'Puedes volver a la pantalla principal y consultar los teléfonos de ayuda.',
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final results = snapshot.data!.where((place) {
                final correctCategory = category == 'all' ||
                    (category == 'seguridad' && place.category != 'centro_sanitario') ||
                    (category == 'centro_sanitario' && place.category == 'centro_sanitario');
                final haystack = '${place.name} ${place.municipality} ${place.address} ${place.categoryLabel}'.toLowerCase();
                return correctCategory && (query.isEmpty || haystack.contains(query));
              }).toList();

              if (widget.latitude != null && widget.longitude != null) {
                results.sort((a, b) {
                  final d1 = a.distanceKm(widget.latitude, widget.longitude);
                  final d2 = b.distanceKm(widget.latitude, widget.longitude);
                  if (d1 == null && d2 == null) return a.name.compareTo(b.name);
                  if (d1 == null) return 1;
                  if (d2 == null) return -1;
                  return d1.compareTo(d2);
                });
              } else {
                results.sort((a, b) {
                  final c = a.municipality.compareTo(b.municipality);
                  return c != 0 ? c : a.name.compareTo(b.name);
                });
              }
              if (results.isEmpty) {
                return const _EmptyState(
                  message: 'No encontramos ese recurso en el listado.',
                  detail: 'Prueba otra localidad o consulta los teléfonos de ayuda. En una emergencia, llama al 112 si hay red telefónica.',
                );
              }
              return ListView.builder(
                key: const ValueKey('offline-place-list'),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final item = results[index];
                  final distance = item.distanceKm(widget.latitude, widget.longitude);
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(item.categoryLabel),
                        if (item.municipality.isNotEmpty) Text(item.municipality),
                        if (item.address.isNotEmpty) Text(item.address),
                        if (distance != null)
                          Text('A ${distance.toStringAsFixed(1)} km en línea recta (ubicación aproximada del edificio)',
                              style: const TextStyle(color: Color(0xFF526170), fontSize: 12)),
                        const Text('Horario y atención urgente: sin confirmar',
                            style: TextStyle(color: Color(0xFF526170), fontSize: 12)),
                        const SizedBox(height: 8),
                        if (item.phone != null && item.phone!.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () => widget.onDial(item.phone!),
                            icon: const Icon(Icons.phone),
                            label: Text('Llamar: ${item.phone}'),
                          ),
                        const Text('Fuente: Gobierno de Navarra · Información descargada',
                          style: TextStyle(color: Color(0xFF526170), fontSize: 11)),
                      ]),
                    ),
                  );
                },
              );
            },
          )),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: FilledButton.icon(
            onPressed: () => widget.onDial('112'),
            style: FilledButton.styleFrom(
              backgroundColor: emergencyRed,
              minimumSize: const Size.fromHeight(54),
            ),
            icon: const Icon(Icons.call),
            label: const Text('Emergencias 112'),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.detail});
  final String message;
  final String detail;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.help_outline, size: 38),
        const SizedBox(height: 10),
        Text(message, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(detail, textAlign: TextAlign.center),
      ]),
    ),
  );
}
