class AuxilioConfig {
  static const double tallerLat = -12.215840;
  static const double tallerLon = -76.931420;

  /// RN-R01: radio máximo de cobertura (acuerdo del equipo).
  static const double radioKm = 3.50;

  static const List<String> fallas = <String>[
    'No enciende',
    'Llanta ponchada',
    'Falla de frenos',
    'Se recalentó',
    'Otro problema',
  ];

  static const List<String> estados = <String>[
    'Pendiente',
    'En camino',
    'Finalizado',
  ];
}
