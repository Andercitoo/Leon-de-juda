class Usuario {
  final int idUsuario;
  final String dni;
  final String nombre;
  final String? telefono;
  final String placaVehiculo;
  final String? modeloMoto;
  final bool soatVigente;

  Usuario({
    required this.idUsuario,
    required this.dni,
    required this.nombre,
    this.telefono,
    required this.placaVehiculo,
    this.modeloMoto,
    required this.soatVigente,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['id_usuario'] ?? 0,
      dni: json['dni']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      telefono: json['telefono'],
      placaVehiculo: json['placa_vehiculo'] ?? json['placa'] ?? '',
      modeloMoto: json['modelo_moto'],
      soatVigente: json['soat_vigente'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'dni': dni,
      'nombre': nombre,
      'telefono': telefono,
      'placa_vehiculo': placaVehiculo,
      'modelo_moto': modeloMoto,
      'soat_vigente': soatVigente,
    };
  }
}