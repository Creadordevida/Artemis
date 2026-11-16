import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'help_contacts.dart';
import 'offline_resources.dart';
import 'help_orientation.dart';
import 'flashlight_control.dart';
import 'navarra_map.dart';

void main() => runApp(const ArtemisApp());

const navy = Color(0xFF14283B);
const tealGrey = Color(0xFFEEF3F2);
const emergencyRed = Color(0xFFAA3945);

class ArtemisApp extends StatelessWidget {
  const ArtemisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Artemis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: navy),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF9FAFB),
          foregroundColor: navy,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? position;
  bool isCurrent = false;
  bool locating = false;
  String status = 'Puedes buscar ayuda aunque no tengamos tu ubicación.';
  String? manualPlace;

  Future<void> _locate() async {
    if (locating) return;
    setState(() { locating = true; status = 'Buscando tu ubicación. La ayuda sigue disponible.'; });
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _setStatus('La ubicación está desactivada. Puedes activarla o indicar tu localidad.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setStatus('No tenemos permiso de ubicación. Puedes buscar ayuda sin compartirla.');
        return;
      }
      final found = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      setState(() {
        position = found;
        isCurrent = true;
        manualPlace = null;
        status = 'Ubicación obtenida. Precisión estimada: ${found.accuracy.round()} m.';
      });
    } catch (_) {
      try {
        final previous = await Geolocator.getLastKnownPosition();
        if (!mounted) return;
        if (previous != null) {
          setState(() {
            position = previous;
            isCurrent = false;
            status = 'Solo tenemos una ubicación anterior. No sabemos si sigues allí.';
          });
        } else {
          _setStatus('Ahora no podemos localizarte. Puedes indicar tu localidad o utilizar teléfonos de ayuda.');
        }
      } catch (_) {
        _setStatus('Ahora no podemos localizarte. Los teléfonos de ayuda siguen disponibles.');
      }
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  void _setStatus(String value) {
    if (mounted) setState(() { status = value; isCurrent = false; });
  }

  Future<void> _dial112() => _dial('112');

  Future<void> _dial(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No pudimos abrir la llamada. Puedes marcar $number desde el teléfono si hay red.'),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Puedes abrir el teléfono y marcar $number si existe una red disponible.'),
        ));
      }
    }
  }

  void _showContacts() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: Column(children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Teléfonos de ayuda', style: TextStyle(
                  fontSize: 23, fontWeight: FontWeight.bold, color: navy)),
                SizedBox(height: 8),
                Text('Estos números están guardados en el móvil. Para llamar necesitas una red telefónica disponible.'),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: helpContacts.length,
                itemBuilder: (context, index) {
                  final contact = helpContacts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(contact.name, style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 5),
                          Text(contact.description),
                          const SizedBox(height: 5),
                          Text('Verificado: ${contact.verifiedOn}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF53616B))),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: () => _dial(contact.phone),
                              icon: const Icon(Icons.phone),
                              label: Text('Llamar al ${contact.phone}'),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _choosePlace() async {
    final controller = TextEditingController(text: manualPlace);
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Dónde estás?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Escribe un pueblo o una referencia que conozcas. Por ahora se guarda como nota; la búsqueda de direcciones offline está pendiente.'),
          const SizedBox(height: 12),
          TextField(controller: controller, autofocus: true, maxLength: 100,
            decoration: const InputDecoration(labelText: 'Localidad o referencia')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Guardar')),
        ],
      ),
    );
    controller.dispose();
    if (selected != null && selected.isNotEmpty && mounted) {
      setState(() {
        manualPlace = selected;
        position = null;
        isCurrent = false;
        status = 'Referencia anotada: $selected. Todavía no se ha localizado en el mapa.';
      });
    }
  }

  void _openResources(String category) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => OfflineResourcesPage(
        initialCategory: category,
        onDial: _dial,
        latitude: isCurrent ? position?.latitude : null,
        longitude: isCurrent ? position?.longitude : null,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final coordinates = position == null ? null :
      '${position!.latitude.toStringAsFixed(5)}, ${position!.longitude.toStringAsFixed(5)}';
    return Scaffold(
      appBar: AppBar(title: const Text('ARTEMIS', style: TextStyle(
        fontWeight: FontWeight.w800, letterSpacing: 1.8)), actions: [
          const FlashlightAction(),
          IconButton(
            tooltip: 'Obtener mi ubicación si lo deseo',
            onPressed: locating ? null : _locate,
            icon: const Icon(Icons.my_location),
          ),
        ]),
      body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        Text('Ayuda cuando la necesitas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Semantics(
          label: 'Enfermera del Consejo Sanitario de Navarra, orientación sanitaria telefónica',
          child: Card(
            color: const Color(0xFFEAF0F2),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.support_agent, color: navy, size: 27),
                  SizedBox(width: 10),
                  Expanded(child: Text('Enfermera de Consejo Sanitario',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                ]),
                const SizedBox(height: 6),
                const Text('¿Tienes dudas sobre tu salud? Puedes hablar con Enfermería de Navarra. Para una emergencia, usa el 112.'),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _dial('948290290'),
                    icon: const Icon(Icons.phone),
                    label: const Text('Llamar · 948 290 290'),
                  ),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(label: 'Panel de ubicación', child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: tealGrey, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(isCurrent ? Icons.location_on : Icons.location_off_outlined, color: navy),
              const SizedBox(width: 9),
              const Expanded(child: Text('Tu ubicación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 9),
            Text(status),
            if (coordinates != null) ...[
              const SizedBox(height: 8),
              SelectableText('${isCurrent ? "Coordenadas obtenidas" : "Últimas coordenadas conocidas"}: $coordinates'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(
                    text: '${isCurrent ? "Posición obtenida" : "Posición anterior, NO confirmada actualmente"}: $coordinates',
                  ));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Coordenadas copiadas. Indica si corresponden a una ubicación anterior.'),
                  ));
                },
                icon: const Icon(Icons.copy),
                label: Text(isCurrent ? 'Copiar coordenadas' : 'Copiar posición anterior'),
              ),
            ],
            if (locating) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: locating ? null : _locate,
              icon: const Icon(Icons.my_location_outlined),
              label: const Text('Obtener mi ubicación'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _choosePlace, icon: const Icon(Icons.edit_location_alt_outlined),
              label: const Text('Indicar dónde estoy')),
          ]),
        )),
        const SizedBox(height: 16),
        Material(
          color: const Color(0xFFE7ECE8),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            key: const ValueKey('open-navarra-map'),
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => NavarraMapPage(
                currentLatitude: isCurrent ? position?.latitude : null,
                currentLongitude: isCurrent ? position?.longitude : null,
                onDial: _dial,
              ),
            )),
            child: const SizedBox(
              height: 155,
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.map_outlined, size: 38, color: navy),
                  SizedBox(height: 8),
                  Text('Abrir mapa de Navarra', style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 17)),
                  SizedBox(height: 4),
                  Text('Calles y recursos públicos offline · mapa online opcional',
                    textAlign: TextAlign.center),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('¿Qué necesitas?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _HelpAction(icon: Icons.medical_services_outlined, label: 'Salud',
            onTap: () => _openResources('centro_sanitario')),
          _HelpAction(icon: Icons.shield_outlined, label: 'Policía',
            onTap: () => _openResources('seguridad')),
          _HelpAction(icon: Icons.phone_in_talk_outlined, label: 'Teléfonos',
            onTap: _showContacts),
          _HelpAction(icon: Icons.help_outline, label: 'No sé qué hacer',
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => HelpOrientationPage(onDial: _dial),
            ))),
        ]),
        const SizedBox(height: 20),
        const Text('Artemis es un prototipo. Los servicios y el mapa de Navarra están en preparación.',
          style: TextStyle(color: Color(0xFF53616B), fontSize: 12)),
      ])),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FilledButton.icon(
              onPressed: _dial112,
              style: FilledButton.styleFrom(
                backgroundColor: emergencyRed,
                minimumSize: const Size.fromHeight(58),
              ),
              icon: const Icon(Icons.call),
              label: const Text('Emergencias 112',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 5),
            const Text('La llamada necesita una red telefónica disponible.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF53616B), fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}

class _HelpAction extends StatelessWidget {
  const _HelpAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: (MediaQuery.sizeOf(context).width - 42) / 2,
    height: 88,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 26),
      label: Text(label, textAlign: TextAlign.center),
      style: OutlinedButton.styleFrom(
        foregroundColor: navy,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
