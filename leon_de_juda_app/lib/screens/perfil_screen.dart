import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../models/pedido.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PerfilScreen extends StatefulWidget {
  final Usuario? usuario;
  final List<Pedido> historialPedidos;
  final VoidCallback? onCerrarSesion;

  const PerfilScreen({
    super.key,
    this.usuario,
    this.historialPedidos = const [],
    this.onCerrarSesion,
  });

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _mostrarTodos = false;

  @override
  Widget build(BuildContext context) {
    final conductor =
        widget.usuario ??
        ApiService.usuarioActual ??
        Usuario(
          idUsuario: 1,
          dni: '70646634',
          nombre: 'Conductor León de Judá',
          telefono: '999888777',
          placaVehiculo: 'ABC123',
          modeloMoto: 'Bajaj RE Torito 4T',
          soatVigente: true,
        );

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Perfil')),
      body: AppPageBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.brandRed,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: AppTheme.amberGradient,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 42,
                          color: AppTheme.brandRed,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        conductor.nombre,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'DNI: ${conductor.dni}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Insignia verde SOAT vigente (#1E8E4E)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              conductor.soatVigente
                                  ? Icons.verified
                                  : Icons.warning_amber_rounded,
                              size: 18,
                              color: conductor.soatVigente
                                  ? const Color(0xFF1E8E4E)
                                  : Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              conductor.soatVigente
                                  ? 'SOAT VIGENTE'
                                  : 'SOAT VENCIDO',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: conductor.soatVigente
                                    ? const Color(0xFF1E8E4E)
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 28,
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                      _filaInfo(
                        Icons.two_wheeler,
                        'Placa del vehículo',
                        conductor.placaVehiculo,
                      ),
                      const SizedBox(height: 10),
                      _filaInfo(
                        Icons.build_circle_outlined,
                        'Modelo de mototaxi',
                        conductor.modeloMoto ?? 'No especificado',
                      ),
                      if (conductor.telefono != null &&
                          conductor.telefono!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _filaInfo(
                          Icons.phone_android,
                          'Teléfono',
                          conductor.telefono!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Sección de historial de pedidos
              const Text(
                'Pedidos recientes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandRed,
                ),
              ),
              const SizedBox(height: 10),
              if (widget.historialPedidos.isEmpty)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 36,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Aún no tienes pedidos registrados.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...widget.historialPedidos
                    .take(_mostrarTodos ? widget.historialPedidos.length : 5)
                    .map(
                      (pedido) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE8EEF5),
                                child: Icon(
                                  Icons.shopping_bag,
                                  color: AppTheme.brandRed,
                                ),
                              ),
                              title: Text(
                                'Pedido #${pedido.idPedido ?? '-'} • ${pedido.modalidadEntrega}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text('Estado: ${pedido.estadoPedido}'),
                              trailing: Text(
                                'S/ ${pedido.totalPagar.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.brandRed,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _mostrarDetallePedido(pedido),
                                icon: const Icon(Icons.receipt_long_outlined),
                                label: const Text('Ver detalle'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              if (widget.historialPedidos.length > 5)
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _mostrarTodos = !_mostrarTodos),
                  icon: Icon(
                    _mostrarTodos ? Icons.expand_less : Icons.expand_more,
                  ),
                  label: Text(
                    _mostrarTodos ? 'Ver menos' : 'Ver pedidos anteriores',
                  ),
                ),

              const SizedBox(height: 24),

              // Botón Cerrar Sesión
              AppGradientButton(
                onPressed: () {
                  if (widget.onCerrarSesion != null) {
                    widget.onCerrarSesion!();
                  } else {
                    ApiService.cerrarSesion();
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  }
                },
                height: 54,
                useGradient: false,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 9),
                    Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetallePedido(Pedido pedido) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Detalle del pedido #${pedido.idPedido ?? '-'}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _filaDetalle('Cliente', pedido.nombreCliente),
                _filaDetalle('Modalidad', pedido.modalidadEntrega),
                _filaDetalle('Estado', pedido.estadoPedido),
                const Divider(height: 24),
                ...pedido.detalles.map((detalle) {
                  final nombre = detalle['nombre']?.toString() ?? 'Repuesto';
                  final cantidad = detalle['cantidad']?.toString() ?? '0';
                  final subtotal =
                      double.tryParse(detalle['subtotal']?.toString() ?? '') ??
                      0;
                  return _filaDetalle(
                    '$nombre × $cantidad',
                    'S/ ${subtotal.toStringAsFixed(2)}',
                  );
                }),
                const Divider(height: 24),
                _filaDetalle(
                  'Subtotal',
                  'S/ ${pedido.subtotal.toStringAsFixed(2)}',
                ),
                _filaDetalle(
                  'Envío',
                  'S/ ${pedido.costoEnvio.toStringAsFixed(2)}',
                ),
                _filaDetalle(
                  'Total',
                  'S/ ${pedido.totalPagar.toStringAsFixed(2)}',
                  destacado: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filaDetalle(String etiqueta, String valor, {bool destacado = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: TextStyle(
                fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            valor,
            style: TextStyle(
              fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaInfo(IconData icono, String etiqueta, String valor) {
    return Row(
      children: [
        Icon(icono, size: 20, color: AppTheme.amberLight),
        const SizedBox(width: 10),
        Text(
          '$etiqueta: ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
