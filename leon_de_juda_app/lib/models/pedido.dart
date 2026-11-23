class Pedido {
  final int? idPedido;
  final String nombreCliente;
  final String modalidadEntrega;
  final double subtotal;
  final double costoEnvio;
  final double totalPagar;
  final String estadoPedido;
  final String? expiraReserva;
  final List<Map<String, dynamic>> detalles;

  Pedido({
    this.idPedido,
    this.nombreCliente = '',
    required this.modalidadEntrega,
    this.subtotal = 0,
    required this.costoEnvio,
    required this.totalPagar,
    required this.estadoPedido,
    this.expiraReserva,
    this.detalles = const [],
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    final rawDetalles = json['detalles'];
    return Pedido(
      idPedido: int.tryParse(json['id_pedido']?.toString() ?? ''),
      nombreCliente: json['nombre_cliente']?.toString() ?? '',
      modalidadEntrega: json['modalidad_entrega'] ?? 'RECOJO_TIENDA',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '') ?? 0,
      costoEnvio: double.tryParse(json['costo_envio'].toString()) ?? 0.0,
      totalPagar: double.tryParse(json['total_pagar'].toString()) ?? 0.0,
      estadoPedido: json['estado_pedido'] ?? 'PENDIENTE',
      expiraReserva: json['expira_reserva']?.toString(),
      detalles: rawDetalles is List
          ? rawDetalles
                .whereType<Map>()
                .map((detalle) => Map<String, dynamic>.from(detalle))
                .toList()
          : const [],
    );
  }

  Pedido copyWith({
    String? estadoPedido,
    String? expiraReserva,
    bool clearExpiraReserva = false,
  }) {
    return Pedido(
      idPedido: idPedido,
      nombreCliente: nombreCliente,
      modalidadEntrega: modalidadEntrega,
      subtotal: subtotal,
      costoEnvio: costoEnvio,
      totalPagar: totalPagar,
      estadoPedido: estadoPedido ?? this.estadoPedido,
      expiraReserva: clearExpiraReserva
          ? null
          : expiraReserva ?? this.expiraReserva,
      detalles: detalles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idPedido != null) 'id_pedido': idPedido,
      'nombre_cliente': nombreCliente,
      'modalidad_entrega': modalidadEntrega,
      'subtotal': subtotal,
      'costo_envio': costoEnvio,
      'total_pagar': totalPagar,
      'estado_pedido': estadoPedido,
      if (expiraReserva != null) 'expira_reserva': expiraReserva,
      'detalles': detalles,
    };
  }
}
