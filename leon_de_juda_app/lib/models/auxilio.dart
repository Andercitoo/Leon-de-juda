class Auxilio {
  final int idAuxilio;
  final double latitud;
  final double longitud;
  final double distanciaKm;
  final String tipoFalla;
  final String estadoAuxilio;

  Auxilio({
    required this.idAuxilio,
    required this.latitud,
    required this.longitud,
    required this.distanciaKm,
    required this.tipoFalla,
    required this.estadoAuxilio,
  });

  factory Auxilio.fromJson(Map<String, dynamic> json) {
    return Auxilio(
      idAuxilio: json['id_auxilio'] ?? 0,
      latitud: double.tryParse(json['latitud'].toString()) ?? 0.0,
      longitud: double.tryParse(json['longitud'].toString()) ?? 0.0,
      distanciaKm: double.tryParse(json['distancia_km'].toString()) ?? 0.0,
      tipoFalla: json['tipo_falla'] ?? '',
      estadoAuxilio: json['estado_auxilio'] ?? 'SOLICITADO',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_auxilio': idAuxilio,
      'latitud': latitud,
      'longitud': longitud,
      'distancia_km': distanciaKm,
      'tipo_falla': tipoFalla,
      'estado_auxilio': estadoAuxilio,
    };
  }
}