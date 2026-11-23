import 'package:flutter_test/flutter_test.dart';
import 'package:leon_de_juda_app/models/pedido.dart';
import 'package:leon_de_juda_app/services/carrito_service.dart';

void main() {
  final carrito = CarritoService.instancia;

  tearDown(carrito.limpiarSesion);

  test('mantiene varias reservas y solo detiene la que se actualiza', () {
    final expira = DateTime.now()
        .add(const Duration(minutes: 10))
        .toIso8601String();
    final anterior = Pedido(
      idPedido: 10,
      modalidadEntrega: CarritoService.modalidadTienda,
      costoEnvio: 0,
      totalPagar: 40,
      estadoPedido: 'Pendiente',
      expiraReserva: expira,
    );
    final reciente = Pedido(
      idPedido: 11,
      modalidadEntrega: CarritoService.modalidadDomicilio,
      costoEnvio: 6,
      totalPagar: 46,
      estadoPedido: 'Pendiente',
      expiraReserva: expira,
    );
    carrito.cargarPedidos([reciente, anterior]);

    expect(carrito.hayReserva, isTrue);
    expect(
      carrito.pedidosPendientesEnOrdenDeCreacion.map(
        (pedido) => pedido.idPedido,
      ),
      [10, 11],
    );

    carrito.actualizarPedido(
      anterior.copyWith(estadoPedido: 'Pagado', clearExpiraReserva: true),
    );

    expect(carrito.pedidosPendientes.map((pedido) => pedido.idPedido), [11]);
    expect(carrito.hayReserva, isTrue);
    expect(
      carrito.pedidosRealizados
          .firstWhere((pedido) => pedido.idPedido == 10)
          .expiraReserva,
      isNull,
    );
  });
}
