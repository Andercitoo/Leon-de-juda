import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/pedido.dart';
import '../models/repuesto.dart';

/// Ítem del carrito en memoria local (antes de confirmar la compra).
class ItemCarrito {
  final Repuesto repuesto;
  int cantidad;

  ItemCarrito({required this.repuesto, this.cantidad = 1});

  double get subtotal => repuesto.precioUnitario * cantidad;
}

/// Estado global del carrito y de la reserva activa.
///
/// Uso: `CarritoService.instancia` (singleton). Es un [ChangeNotifier], así
/// que cualquier pantalla (catálogo, carrito, contador rojo de la barra
/// inferior, home) puede escucharlo con [ListenableBuilder].
class CarritoService extends ChangeNotifier {
  CarritoService._();
  static final CarritoService instancia = CarritoService._();

  // Acuerdos técnicos del equipo
  static const double montoMinEnvio = 30.00; // RN-P01
  static const double costoEnvio = 6.00; // RN-P01
  static const Duration tiempoReserva = Duration(minutes: 15); // RN-V01

  // Valores que espera la BD (CHECK de pedido.modalidad_entrega)
  static const String modalidadTienda = 'Recojo en tienda';
  static const String modalidadDomicilio = 'Delivery';

  final Map<int, ItemCarrito> _items = {};

  List<ItemCarrito> get items => _items.values.toList();
  bool get estaVacio => _items.isEmpty;

  /// Total de unidades (para el contador rojo de la pestaña Carrito).
  int get totalUnidades => _items.values.fold(0, (acc, i) => acc + i.cantidad);

  double get subtotal => _items.values.fold(0.0, (acc, i) => acc + i.subtotal);

  /// RN-P01: el envío a domicilio solo se habilita desde S/ 30.00.
  bool get envioDisponible => subtotal >= montoMinEnvio;

  int cantidadDe(int idRepuesto) => _items[idRepuesto]?.cantidad ?? 0;

  /// Agrega una unidad respetando el stock disponible. Devuelve false si no hay más stock.
  bool agregar(Repuesto repuesto) {
    final actual = cantidadDe(repuesto.idRepuesto);
    if (actual >= repuesto.stockDisponible) return false;
    _items.putIfAbsent(
      repuesto.idRepuesto,
      () => ItemCarrito(repuesto: repuesto, cantidad: 0),
    );
    _items[repuesto.idRepuesto]!.cantidad++;
    notifyListeners();
    return true;
  }

  void quitar(int idRepuesto) {
    final item = _items[idRepuesto];
    if (item == null) return;
    item.cantidad--;
    if (item.cantidad <= 0) _items.remove(idRepuesto);
    notifyListeners();
  }

  void eliminar(int idRepuesto) {
    _items.remove(idRepuesto);
    notifyListeners();
  }

  /// Actualiza el stock de los ítems con datos frescos del catálogo.
  void sincronizarStock(List<Repuesto> catalogo) {
    var cambio = false;
    for (final rep in catalogo) {
      final item = _items[rep.idRepuesto];
      if (item != null) {
        _items[rep.idRepuesto] = ItemCarrito(
          repuesto: rep,
          cantidad: item.cantidad > rep.stockDisponible ? rep.stockDisponible : item.cantidad,
        );
        if (_items[rep.idRepuesto]!.cantidad <= 0) _items.remove(rep.idRepuesto);
        cambio = true;
      }
    }
    if (cambio) notifyListeners();
  }

  void vaciar() {
    _items.clear();
    notifyListeners();
  }

  /// Cuerpo de `repuestos` para POST /api/pedidos.
  List<Map<String, dynamic>> toPedidoJson() => _items.values
      .map((i) => {
            'id_repuesto': i.repuesto.idRepuesto,
            'cantidad': i.cantidad,
            'precio': i.repuesto.precioUnitario,
          })
      .toList();

  // ---------------- Reserva activa (RN-V01) ----------------

  Pedido? _pedidoReservado;
  DateTime? _expiraEn;
  Timer? _timer;

  /// Pedidos creados en esta sesión (para la lista de PerfilScreen.historialPedidos).
  final List<Pedido> pedidosRealizados = [];

  Pedido? get pedidoReservado => _pedidoReservado;
  bool get hayReserva => _pedidoReservado != null && tiempoRestante > Duration.zero;

  Duration get tiempoRestante {
    if (_expiraEn == null) return Duration.zero;
    final r = _expiraEn!.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  /// Texto MM:SS del temporizador regresivo.
  String get tiempoRestanteTexto {
    final t = tiempoRestante;
    final mm = t.inMinutes.toString().padLeft(2, '0');
    final ss = (t.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  /// Se llama tras el 201 Created de POST /api/pedidos.
  /// El conteo se hace con el reloj del dispositivo (15:00 desde la respuesta)
  /// para no depender de la diferencia horaria entre el emulador y la PC.
  void iniciarReserva(Pedido pedido) {
    _pedidoReservado = pedido;
    pedidosRealizados.insert(0, pedido);
    _expiraEn = DateTime.now().add(tiempoReserva);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (tiempoRestante == Duration.zero) {
        _timer?.cancel();
      }
      notifyListeners();
    });
    _items.clear();
    notifyListeners();
  }

  bool get reservaExpirada => _pedidoReservado != null && tiempoRestante == Duration.zero;

  void cerrarReserva() {
    _timer?.cancel();
    _timer = null;
    _pedidoReservado = null;
    _expiraEn = null;
    notifyListeners();
  }
}
