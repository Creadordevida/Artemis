import 'package:flutter/material.dart';

/// Offline-first decision support. No diagnosis, personal data collection,
/// AI-generated recommendations or network calls. The options deliberately
/// never delay the visible 112 action.
enum HelpSituation {
  unwell,
  unsafe,
  lost,
  someoneElse,
  needToTalk,
  unsure,
}

class HelpGuidance {
  const HelpGuidance({
    required this.title,
    required this.nextStep,
    required this.alternative,
    this.phone,
    this.phoneLabel,
  });
  final String title;
  final String nextStep;
  final String alternative;
  final String? phone;
  final String? phoneLabel;
}

HelpGuidance guidanceFor(HelpSituation situation) {
  switch (situation) {
    case HelpSituation.unwell:
      return const HelpGuidance(
        title: 'Me encuentro mal',
        nextStep:
            'Si puedes, siéntate en un lugar seguro y avisa a una persona adulta de confianza.',
        alternative:
            'Para dudas de salud no urgentes, puedes hablar con la enfermera del Consejo Sanitario. Si tienes dificultad importante para respirar, pierdes el conocimiento o hay peligro inmediato, llama al 112.',
        phone: '948290290',
        phoneLabel: 'Hablar con Enfermería',
      );
    case HelpSituation.unsafe:
      return const HelpGuidance(
        title: 'Tengo miedo o no me siento seguro',
        nextStep:
            'Si puedes hacerlo sin ponerte en peligro, aléjate de la situación y busca un lugar con otras personas o personal que pueda ayudarte.',
        alternative:
            'Pide ayuda a una persona adulta de confianza. Si alguien te amenaza o hay peligro inmediato, llama al 112. Puedes hablar también con ANAR si necesitas apoyo.',
        phone: '116111',
        phoneLabel: 'Hablar con ANAR',
      );
    case HelpSituation.lost:
      return const HelpGuidance(
        title: 'No sé dónde estoy',
        nextStep:
            'Quédate en un lugar seguro y reconocible. Evita desplazarte por zonas desconocidas o peligrosas para buscar cobertura.',
        alternative:
            'Puedes mirar tus coordenadas en el inicio, pedir ayuda en un lugar atendido o llamar a alguien de confianza. Si estás en peligro, llama al 112.',
      );
    case HelpSituation.someoneElse:
      return const HelpGuidance(
        title: 'Otra persona necesita ayuda',
        nextStep:
            'Comprueba primero que es seguro acercarte. Avisa a una persona adulta o a quienes estén cerca.',
        alternative:
            'Si la persona no responde, respira con dificultad o existe peligro inmediato, llama al 112. Sigue las indicaciones del personal de emergencias y no te pongas en riesgo.',
      );
    case HelpSituation.needToTalk:
      return const HelpGuidance(
        title: 'Necesito hablar con alguien',
        nextStep:
            'Puedes contar lo que te pasa con tus propias palabras. No necesitas tenerlo todo claro para pedir ayuda.',
        alternative:
            'Busca a una persona adulta de confianza. ANAR escucha y orienta a niños y adolescentes; también puedes llamarlos.',
        phone: '116111',
        phoneLabel: 'Hablar con ANAR',
      );
    case HelpSituation.unsure:
      return const HelpGuidance(
        title: 'No sé qué ocurre',
        nextStep:
            'No necesitas saber exactamente qué te pasa. Primero busca un sitio seguro y toma contacto con alguien de confianza.',
        alternative:
            'Puedes elegir una de las otras opciones o pedir orientación a ANAR. Si existe peligro inmediato para ti o para alguien más, llama al 112.',
        phone: '116111',
        phoneLabel: 'Hablar con ANAR',
      );
  }
}

class HelpOrientationPage extends StatefulWidget {
  const HelpOrientationPage({super.key, required this.onDial});
  final Future<void> Function(String) onDial;

  @override
  State<HelpOrientationPage> createState() => _HelpOrientationPageState();
}

class _HelpOrientationPageState extends State<HelpOrientationPage> {
  HelpSituation? selected;

  @override
  Widget build(BuildContext context) {
    final guidance = selected == null ? null : guidanceFor(selected!);
    return Scaffold(
      appBar: AppBar(title: const Text('Vamos a ayudarte')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              guidance == null ? '¿Qué te preocupa?' : guidance.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            if (guidance == null) ...[
              const Text('Elige lo que más se parezca a tu situación. Si no lo sabes, también está bien.'),
              const SizedBox(height: 18),
              _option('Me encuentro mal', Icons.healing_outlined, HelpSituation.unwell),
              _option('Tengo miedo o no me siento seguro', Icons.shield_outlined, HelpSituation.unsafe),
              _option('No sé dónde estoy', Icons.location_off_outlined, HelpSituation.lost),
              _option('Otra persona necesita ayuda', Icons.people_outline, HelpSituation.someoneElse),
              _option('Necesito hablar con alguien', Icons.forum_outlined, HelpSituation.needToTalk),
              _option('No sé qué ocurre', Icons.help_outline, HelpSituation.unsure),
            ] else ...[
              const Text('Primer paso', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(guidance.nextStep),
              const SizedBox(height: 18),
              const Text('Otra opción', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(guidance.alternative),
              const SizedBox(height: 18),
              if (guidance.phone != null)
                OutlinedButton.icon(
                  onPressed: () => widget.onDial(guidance.phone!),
                  icon: const Icon(Icons.call_outlined),
                  label: Text('${guidance.phoneLabel} · ${guidance.phone}'),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() => selected = null),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Elegir otra situación'),
              ),
            ],
            const SizedBox(height: 12),
            const Text('Orientación general guardada en el móvil. No sustituye al personal de emergencias ni ofrece diagnósticos.',
              style: TextStyle(fontSize: 12, color: Color(0xFF596876))),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 7, 16, 12),
          child: FilledButton.icon(
            key: const ValueKey('emergency-112'),
            onPressed: () => widget.onDial('112'),
            icon: const Icon(Icons.phone),
            label: const Text('Emergencias 112'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFAA3945),
              minimumSize: const Size.fromHeight(56),
            ),
          ),
        ),
      ),
    );
  }

  Widget _option(String label, IconData icon, HelpSituation situation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: OutlinedButton.icon(
        onPressed: () => setState(() => selected = situation),
        icon: Icon(icon),
        label: Align(alignment: Alignment.centerLeft, child: Text(label)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(57),
          foregroundColor: const Color(0xFF14283B),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
