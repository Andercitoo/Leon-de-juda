class Repuesto {
  final int idRepuesto;
  final String nombre;
  final String marca;
  final String categoriaAveria;
  final double precioUnitario;
  final int stockDisponible;

  Repuesto({
    required this.idRepuesto,
    required this.nombre,
    required this.marca,
    required this.categoriaAveria,
    required this.precioUnitario,
    required this.stockDisponible,
  });

  factory Repuesto.fromJson(Map<String, dynamic> json) {
    return Repuesto(
      idRepuesto: json['id_repuesto'] ?? 0,
      nombre: json['nombre'] ?? '',
      marca: json['marca'] ?? '',
      categoriaAveria: json['categoria_averia'] ?? '',
      precioUnitario: double.tryParse(json['precio_unitario'].toString()) ?? 0.0,
      stockDisponible: int.tryParse(json['stock_disponible'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_repuesto': idRepuesto,
      'nombre': nombre,
      'marca': marca,
      'categoria_averia': categoriaAveria,
      'precio_unitario': precioUnitario,
      'stock_disponible': stockDisponible,
    };
  }
}