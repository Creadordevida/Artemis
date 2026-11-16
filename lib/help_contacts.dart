/// Directorio telefónico integrado de emergencia y ayuda, consultable sin red.
/// Los números y fuentes requieren revisiones periódicas antes de publicar.
class HelpContact {
  const HelpContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.description,
    required this.source,
    required this.verifiedOn,
    this.emergency = false,
  });

  final String id;
  final String name;
  final String phone;
  final String description;
  final String source;
  final String verifiedOn;
  final bool emergency;
}

const helpContacts = <HelpContact>[
  HelpContact(
    id: 'navarra_112',
    name: 'Emergencias SOS Navarra',
    phone: '112',
    description: 'Peligro inmediato, accidentes graves, incendios o urgencias médicas.',
    source: 'https://www.navarra.es/es/seguridad-y-emergencias/emergencias-112',
    verifiedOn: '2026-11-16',
    emergency: true,
  ),
  HelpContact(
    id: 'anar_116111',
    name: 'Ayuda a niños y adolescentes (ANAR)',
    phone: '116111',
    description: 'Puedes hablar con profesionales si algo te preocupa o necesitas apoyo.',
    source: 'https://www.anar.org/que-hacemos/telefono-chat-anar/',
    verifiedOn: '2026-11-16',
  ),
  HelpContact(
    id: 'consejo_sanitario',
    name: 'Enfermera de Consejo Sanitario (Navarra)',
    phone: '948290290',
    description: 'Orientación de Enfermería para dudas sobre síntomas, tratamientos y cuidados no urgentes. Si hay peligro inmediato, llama al 112.',
    source: 'https://portalsalud.navarra.es/es/ciudadania/atencion-pacientes/contacto/consejo-sanitario',
    verifiedOn: '2026-11-16',
  ),
  HelpContact(
    id: 'farmacias_guardia',
    name: 'Información sobre farmacias de guardia',
    phone: '948226000',
    description: 'Consulta telefónica sobre farmacias de guardia en Navarra.',
    source: 'https://www.navarra.es/es/seguridad-y-emergencias/emergencias-112',
    verifiedOn: '2026-11-16',
  ),
  HelpContact(
    id: 'guardia_civil',
    name: 'Guardia Civil',
    phone: '062',
    description: 'Atención de urgencias por Guardia Civil las 24 horas.',
    source: 'https://web.guardiacivil.es/es/tramites/formascontacto_131219/',
    verifiedOn: '2026-11-16',
    emergency: true,
  ),
  HelpContact(
    id: 'navarra_carreteras',
    name: 'Información de carreteras de Navarra',
    phone: '848423500',
    description: 'Información sobre cortes, obras y estado de las carreteras.',
    source: 'https://obraspublicas.navarra.es/es/info',
    verifiedOn: '2026-11-16',
  ),
];
