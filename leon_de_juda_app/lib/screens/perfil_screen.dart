import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/pedido.dart';
import '../services/api_service.dart';

class PerfilScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final conductor = usuario ??
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
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          'Perfil del Conductor',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta principal del conductor y vehículo
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      backgroundColor: Color(0xFF1B263B),
                      child: Icon(Icons.person, size: 38, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      conductor.nombre,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'DNI: ${conductor.dni}',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    // Insignia verde SOAT vigente (#1E8E4E)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: conductor.soatVigente
                            ? const Color(0xFF1E8E4E).withOpacity(0.14)
                            : Colors.red.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: conductor.soatVigente
                              ? const Color(0xFF1E8E4E)
                              : Colors.red,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            conductor.soatVigente ? Icons.verified : Icons.warning_amber_rounded,
                            size: 18,
                            color: conductor.soatVigente
                                ? const Color(0xFF1E8E4E)
                                : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            conductor.soatVigente ? 'SOAT VIGENTE' : 'SOAT VENCIDO',
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
                    const Divider(height: 28),
                    _filaInfo(Icons.two_wheeler, 'Placa del vehículo', conductor.placaVehiculo),
                    const SizedBox(height: 10),
                    _filaInfo(
                      Icons.build_circle_outlined,
                      'Modelo de mototaxi',
                      conductor.modeloMoto ?? 'No especificado',
                    ),
                    if (conductor.telefono != null && conductor.telefono!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _filaInfo(Icons.phone_android, 'Teléfono', conductor.telefono!),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Sección de historial de pedidos
            const Text(
              'Mis Pedidos Recientes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B263B)),
            ),
            const SizedBox(height: 10),
            if (historialPedidos.isEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 36, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Aún no tienes pedidos registrados en esta sesión.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...historialPedidos.map(
                (pedido) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8EEF5),
                      child: Icon(Icons.shopping_bag, color: Color(0xFF1B263B)),
                    ),
                    title: Text(
                      'Pedido #${pedido.idPedido ?? '-'} • ${pedido.modalidadEntrega}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text('Estado: ${pedido.estadoPedido}'),
                    trailing: Text(
                      'S/ ${pedido.totalPagar.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1E8E4E),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Botón Cerrar Sesión
            ElevatedButton.icon(
              onPressed: () {
                ApiService.cerrarSesion();
                if (onCerrarSesion != null) {
                  onCerrarSesion!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaInfo(IconData icono, String etiqueta, String valor) {
    return Row(
      children: [
        Icon(icono, size: 20, color: const Color(0xFF1B263B)),
        const SizedBox(width: 10),
        Text('$etiqueta: ', style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}