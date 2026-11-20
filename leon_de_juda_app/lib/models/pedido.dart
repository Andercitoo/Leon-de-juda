class Pedido {
  final int? idPedido;
  final String modalidadEntrega;
  final double costoEnvio;
  final double totalPagar;
  final String estadoPedido;
  final String? expiraReserva;

  Pedido({
    this.idPedido,
    required this.modalidadEntrega,
    required this.costoEnvio,
    required this.totalPagar,
    required this.estadoPedido,
    this.expiraReserva,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      idPedido: json['id_pedido'],
      modalidadEntrega: json['modalidad_entrega'] ?? 'RECOJO_TIENDA',
      costoEnvio: double.tryParse(json['costo_envio'].toString()) ?? 0.0,
      totalPagar: double.tryParse(json['total_pagar'].toString()) ?? 0.0,
      estadoPedido: json['estado_pedido'] ?? 'PENDIENTE',
      expiraReserva: json['expira_reserva']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idPedido != null) 'id_pedido': idPedido,
      'modalidad_entrega': modalidadEntrega,
      'costo_envio': costoEnvio,
      'total_pagar': totalPagar,
      'estado_pedido': estadoPedido,
      if (expiraReserva != null) 'expira_reserva': expiraReserva,
    };
  }
}