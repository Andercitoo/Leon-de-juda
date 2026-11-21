import 'package:flutter/material.dart';
import '../models/pedido.dart';
import '../services/api_service.dart';
import '../services/carrito_service.dart';
import '../theme/app_theme.dart';

/// cartView del prototipo HTML.
/// - Ítems y cantidades en memoria local (CarritoService).
/// - RN-P01: subtotal < S/ 30.00 deshabilita "Envío a domicilio" y fuerza "Recojo en tienda".
/// - RN-V02: "Confirmar pedido" deshabilitado hasta marcar "Acepto el desglose de costos".
/// - RN-V01: al confirmar se dispara POST /api/pedidos (reserva atómica en PostgreSQL)
///   y se muestra el temporizador de 15:00, o la alerta 409 Conflict si el stock se agotó.
class CarritoScreen extends StatefulWidget {
  /// Callback para volver a la pestaña Catálogo dentro de MainNavScreen.
  /// Si es null, "Ir al catálogo" hace Navigator.pop.
  final VoidCallback? onIrAlCatalogo;

  const CarritoScreen({super.key, this.onIrAlCatalogo});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  final CarritoService carrito = CarritoService.instancia;

  String modalidadEntrega = CarritoService.modalidadTienda;
  bool aceptaDesglose = false;
  bool enviando = false;

  String formatoSoles(double monto) => 'S/ ${monto.toStringAsFixed(2)}';

  void irAlCatalogo() {
    if (widget.onIrAlCatalogo != null) {
      widget.onIrAlCatalogo!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> confirmarPedido() async {
    // RN-V02: doble verificación (el botón ya está deshabilitado)
    if (!aceptaDesglose || carrito.estaVacio) return;

    // RN-P01: nunca enviar DOMICILIO con subtotal < 30
    final modalidad =
        carrito.envioDisponible ? modalidadEntrega : CarritoService.modalidadTienda;

    setState(() => enviando = true);
    try {
      final Pedido pedido = await ApiService.crearPedido(
        modalidadEntrega: modalidad,
        repuestos: carrito.toPedidoJson(),
      );
      if (!mounted) return;
      carrito.iniciarReserva(pedido); // 201 Created → temporizador 15:00
      setState(() {
        aceptaDesglose = false;
        modalidadEntrega = CarritoService.modalidadTienda;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido creado ✔ (201 Created) — stock reservado por 15 min'),
          backgroundColor: AppTheme.confirmGreen,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      mostrarError(e);
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  void mostrarError(ApiException e) {
    final String titulo;
    final IconData icono;
    String detalle = e.mensaje;

    switch (e.statusCode) {
      case 409:
        titulo = '409 Conflict — Stock agotado';
        icono = Icons.inventory_2_outlined;
        detalle = '${e.mensaje}\n\nOtro conductor reservó la última unidad. '
            'Ajusta tu carrito y vuelve a intentarlo.';
        break;
      case 401:
      case 403:
        titulo = '${e.statusCode} — Sesión no válida';
        icono = Icons.lock_outline;
        detalle = '${e.mensaje}\n\nCierra sesión e ingresa nuevamente con tu DNI y contraseña.';
        break;
      case 400:
      case 422:
        titulo = '${e.statusCode} — Datos inválidos';
        icono = Icons.error_outline;
        break;
      case 0:
        titulo = 'Sin conexión';
        icono = Icons.cloud_off;
        break;
      default:
        titulo = 'Error ${e.statusCode}';
        icono = Icons.error_outline;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(icono, color: AppTheme.alertRed, size: 40),
        title: Text(titulo, textAlign: TextAlign.center),
        content: Text(detalle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(color: AppTheme.alertRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListenableBuilder(
        listenable: carrito,
        builder: (context, _) {
          // RN-P01: si el subtotal baja de 30, forzar recojo en tienda
          if (!carrito.envioDisponible &&
              modalidadEntrega == CarritoService.modalidadDomicilio) {
            modalidadEntrega = CarritoService.modalidadTienda;
          }

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              if (carrito.pedidoReservado != null) buildTarjetaReserva(),
              if (carrito.estaVacio)
                buildCarritoVacio()
              else
                ...buildDetalleCarrito(),
            ],
          );
        },
      ),
    );
  }

  // ---------------- Reserva activa (temporizador 15:00) ----------------

  Widget buildTarjetaReserva() {
    final pedido = carrito.pedidoReservado!;
    final expirada = carrito.reservaExpirada;
    final colorBorde = expirada ? AppTheme.alertRed : AppTheme.confirmGreen;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorBorde, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(expirada ? Icons.timer_off_outlined : Icons.check_circle,
                    color: colorBorde),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    expirada
                        ? 'Reserva expirada'
                        : 'Pedido PED-${(pedido.idPedido ?? 0).toString().padLeft(4, '0')} reservado',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: expirada ? const Color(0xFFFBE4E4) : const Color(0xFFFDF3DC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    expirada ? 'Stock liberado' : '⏱ Stock reservado (RN-V01)',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    carrito.tiempoRestanteTexto,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: expirada ? AppTheme.alertRed : AppTheme.darkText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            filaMonto(
              'Modalidad',
              pedido.modalidadEntrega == CarritoService.modalidadDomicilio
                  ? 'Envío a domicilio'
                  : 'Recojo en tienda',
            ),
            filaMonto('Envío', formatoSoles(pedido.costoEnvio)),
            filaMonto('Total a pagar', formatoSoles(pedido.totalPagar), destacado: true),
            filaMonto('Estado', pedido.estadoPedido),
            const SizedBox(height: 6),
            Text(
              expirada
                  ? 'No se confirmó a tiempo; el servidor devolvió el stock al catálogo.'
                  : 'Acércate al taller (o espera tu envío) antes de que termine el tiempo.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6F6A5E)),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: carrito.cerrarReserva,
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Carrito vacío ----------------

  Widget buildCarritoVacio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Tu carrito está vacío. Ve al catálogo para agregar repuestos.',
              style: TextStyle(color: Color(0xFF6F6A5E)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: irAlCatalogo,
          icon: const Icon(Icons.build_outlined),
          label: const Text('Ir al catálogo', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(foregroundColor: const Color(0xFF1A1200)),
        ),
      ],
    );
  }

  // ---------------- Detalle, modalidad, desglose y confirmación ----------------

  List<Widget> buildDetalleCarrito() {
    final subtotal = carrito.subtotal;
    final envioDisponible = carrito.envioDisponible;
    final costoEnvio =
        modalidadEntrega == CarritoService.modalidadDomicilio ? CarritoService.costoEnvio : 0.0;
    final total = subtotal + costoEnvio;

    return [
      ...carrito.items.map(buildItem),
      const SizedBox(height: 8),
      const Text('Modalidad de entrega',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: botonModalidad(
              texto: '🏪 Recojo en tienda',
              valor: CarritoService.modalidadTienda,
              habilitado: true,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: botonModalidad(
              texto: '🛵 Envío a domicilio\n+ ${formatoSoles(CarritoService.costoEnvio)}',
              valor: CarritoService.modalidadDomicilio,
              habilitado: envioDisponible, // RN-P01
            ),
          ),
        ],
      ),
      if (!envioDisponible)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'RN-P01: el envío aplica desde ${formatoSoles(CarritoService.montoMinEnvio)}; '
            'tu pedido pasa a recojo en tienda.',
            style: const TextStyle(color: AppTheme.alertRed, fontSize: 13),
          ),
        ),
      const SizedBox(height: 10),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              filaMonto('Subtotal', formatoSoles(subtotal)),
              filaMonto('Envío', formatoSoles(costoEnvio)),
              const Divider(color: Color(0xFFE3DDCF)),
              filaMonto('Total', formatoSoles(total), destacado: true),
            ],
          ),
        ),
      ),
      // RN-V02
      CheckboxListTile(
        value: aceptaDesglose,
        onChanged: enviando ? null : (v) => setState(() => aceptaDesglose = v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        activeColor: AppTheme.primaryAmber,
        title: const Text('Acepto el desglose de costos (RN-V02)'),
      ),
      const SizedBox(height: 4),
      ElevatedButton(
        onPressed: (aceptaDesglose && !enviando) ? confirmarPedido : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.confirmGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.confirmGreen.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: enviando
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : const Text('Confirmar pedido',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      const SizedBox(height: 6),
      TextButton(
        onPressed: enviando ? null : carrito.vaciar,
        child: const Text('Vaciar carrito', style: TextStyle(color: AppTheme.alertRed)),
      ),
    ];
  }

  Widget buildItem(ItemCarrito item) {
    final r = item.repuesto;
    final puedeSumar = item.cantidad < r.stockDisponible;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${formatoSoles(r.precioUnitario)} c/u · ${formatoSoles(item.subtotal)}',
                    style: const TextStyle(color: Color(0xFF6F6A5E), fontSize: 13),
                  ),
                ],
              ),
            ),
            botonCantidad(Icons.remove, enviando ? null : () => carrito.quitar(r.idRepuesto)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('${item.cantidad}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            botonCantidad(
              Icons.add,
              (puedeSumar && !enviando) ? () => carrito.agregar(r) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget botonCantidad(IconData icono, VoidCallback? onPressed) {
    return SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: Color(0xFFE3DDCF)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          foregroundColor: AppTheme.darkText,
        ),
        child: Icon(icono, size: 18),
      ),
    );
  }

  Widget botonModalidad({
    required String texto,
    required String valor,
    required bool habilitado,
  }) {
    final activo = modalidadEntrega == valor;
    return SizedBox(
      height: 58,
      child: ElevatedButton(
        onPressed: (habilitado && !enviando)
            ? () => setState(() => modalidadEntrega = valor)
            : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          backgroundColor: activo ? AppTheme.primaryAmber : Colors.white,
          foregroundColor: activo ? const Color(0xFF1A1200) : AppTheme.darkText,
          disabledBackgroundColor: const Color(0xFFEDEAE3),
          disabledForegroundColor: Colors.black38,
          elevation: activo ? 2 : 0,
          side: BorderSide(color: activo ? AppTheme.primaryAmber : const Color(0xFFE3DDCF)),
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget filaMonto(String etiqueta, String valor, {bool destacado = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta,
              style: TextStyle(fontWeight: destacado ? FontWeight.bold : FontWeight.normal)),
          Text(
            valor,
            style: TextStyle(
              fontWeight: destacado ? FontWeight.w800 : FontWeight.normal,
              fontSize: destacado ? 17 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
