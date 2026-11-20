import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/usuario.dart';
import '../models/repuesto.dart';
import '../models/pedido.dart';
import '../models/auxilio.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  static String? _token;
  static Usuario? usuarioActual;

  static Map<String, String> _headers({bool auth = false}) {
    final headers = {'Content-Type': 'application/json'};
    if (auth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static void cerrarSesion() {
    _token = null;
    usuarioActual = null;
  }

  // POST /api/auth/login
  static Future<Usuario> login(String dni, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(),
      body: jsonEncode({'dni': dni, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      _token = data['token'];
      usuarioActual = Usuario.fromJson(data['usuario']);
      return usuarioActual!;
    } else {
      throw Exception(data['error'] ?? 'Error al iniciar sesión (${response.statusCode})');
    }
  }

  // POST /api/auth/registro
  static Future<Usuario> registrar({
    required String dni,
    required String nombre,
    String? telefono,
    required String placaVehiculo,
    String? modeloMoto,
    required bool soatVigente,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/registro'),
      headers: _headers(),
      body: jsonEncode({
        'dni': dni,
        'nombre': nombre,
        'telefono': telefono,
        'placa_vehiculo': placaVehiculo,
        'modelo_moto': modeloMoto,
        'soat_vigente': soatVigente,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return Usuario.fromJson(data['usuario']);
    } else {
      throw Exception(data['error'] ?? 'Error en el registro (${response.statusCode})');
    }
  }

  // GET /api/repuestos
  static Future<List<Repuesto>> getRepuestos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/repuestos'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> lista = jsonDecode(response.body);
      return lista.map((item) => Repuesto.fromJson(item)).toList();
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Error al cargar repuestos');
    }
  }

  // POST /api/pedidos
  // Cada item de repuestos debe tener: {'id_repuesto': int, 'cantidad': int, 'precio': double}
  static Future<Pedido> crearPedido({
    required String modalidadEntrega, // 'Delivery' o 'Recojo en tienda'
    required List> repuestos,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pedidos'),
      headers: _headers(auth: true),
      body: jsonEncode({
        'id_usuario': usuarioActual?.idUsuario,
        'modalidad_entrega': modalidadEntrega,
        'repuestos': repuestos,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Pedido.fromJson(data['pedido'] ?? data);
    } else {
      throw Exception(data['error'] ?? 'Error al generar pedido (${response.statusCode})');
    }
  }

  // POST /api/auxilios
  static Future<Auxilio> solicitarAuxilio({
    required double latitud,
    required double longitud,
    required String tipoFalla,
    String? referencia,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auxilios'),
      headers: _headers(auth: true),
      body: jsonEncode({
        'latitud': latitud,
        'longitud': longitud,
        'tipo_falla': tipoFalla,
        if (referencia != null) 'referencia': referencia,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Auxilio.fromJson(data['auxilio'] ?? data);
    } else {
      throw Exception(data['error'] ?? 'Error al solicitar auxilio (${response.statusCode})');
    }
  }

  // PATCH /api/auxilios/:id
  // Valores válidos: 'Pendiente', 'En camino', 'Finalizado'
  static Future<Auxilio> actualizarAuxilio(int idAuxilio, String estado) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/auxilios/$idAuxilio'),
      headers: _headers(auth: true),
      body: jsonEncode({'estado': estado}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return Auxilio.fromJson(data['auxilio'] ?? data);
    } else {
      throw Exception(data['error'] ?? 'Error al actualizar auxilio');
    }
  }
}