import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../config/auxilio_config.dart';
import '../models/auxilio.dart';
import '../services/api_service.dart';
import '../services/auxilio_respuesta.dart';
import '../theme/app_theme.dart';
import '../utils/auxilio_geo.dart';

class AuxilioScreen extends StatefulWidget {
  const AuxilioScreen({super.key});

  @override
  State<AuxilioScreen> createState() => _AuxilioScreenState();
}

class _AuxilioScreenState extends State<AuxilioScreen> {
  static const LatLng _taller = LatLng(
    AuxilioConfig.tallerLat,
    AuxilioConfig.tallerLon,
  );

  final MapController _mapController = MapController();
  final TextEditingController _referenciaController = TextEditingController();

  StreamSubscription<Position>? _positionSubscription;

  LatLng _rider = const LatLng(
    AuxilioConfig.tallerLat + 0.010,
    AuxilioConfig.tallerLon + 0.012,
  );
  double _zoomActual = 14.5;
  bool _gpsActive = true;
  bool _locating = false;
  bool _modoSimulacion = false;
  bool _submitting = false;
  bool _advancing = false;
  String? _gpsError;
  String _falla = AuxilioConfig.fallas.first;
  Auxilio? _auxilio;
  AuxilioRespuesta? _respuesta;

  double get _distanciaKm => distanciaEntre(_taller, _rider);
  bool get _enCobertura => _distanciaKm <= AuxilioConfig.radioKm;
  bool get _auxilioActivo =>
      _auxilio != null && !_esFinalizado(_auxilio!.estadoAuxilio);

  @override
  void initState() {
    super.initState();
    _iniciarGps();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _referenciaController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  static bool _esFinalizado(String estado) =>
      estado.trim().toLowerCase() == 'finalizado';

  static int _indiceEstado(String estado) {
    final index = AuxilioConfig.estados.indexOf(estado);
    return index < 0 ? 0 : index;
  }

  // ------------------------------------------------------------------ GPS
  Future<void> _iniciarGps() async {
    if (mounted) setState(() => _locating = true);
    try {
      final servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) {
        _fallarGps('El servicio de ubicación del dispositivo está desactivado.');
        return;
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        _fallarGps('Permiso de ubicación denegado. Habilítalo en los ajustes '
            'del sistema para pedir auxilio.');
        return;
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _rider = LatLng(posicion.latitude, posicion.longitude);
        _gpsActive = true;
        _locating = false;
        _gpsError = null;
        _modoSimulacion = false;
      });
      _escucharPosiciones();
    } catch (e) {
      _fallarGps('No se pudo obtener la ubicación: $e');
    }
  }

  void _escucharPosiciones() {
    _positionSubscription?.cancel();
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (posicion) {
        if (!mounted) return;
        setState(() => _rider = LatLng(posicion.latitude, posicion.longitude));
      },
      onError: (Object e) => _fallarGps('Se perdió la señal GPS: $e'),
    );
  }

  void _fallarGps(String mensaje) {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    if (!mounted) return;
    setState(() {
      _gpsActive = false;
      _locating = false;
      _gpsError = mensaje;
    });
  }

  void _detenerGps() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    setState(() {
      _gpsActive = false;
      _locating = false;
      _gpsError = 'GPS desactivado manualmente. El envío está bloqueado.';
    });
  }

  // ------------------------------------------------------------- Mapa
  void _moverRider(LatLng punto) {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    setState(() {
      _rider = punto;
      _modoSimulacion = true;
    });
  }

  void _ajustarZoom(double delta) {
    final nuevoZoom = (_zoomActual + delta).clamp(11.0, 18.0);
    if (nuevoZoom == _zoomActual) return;
    final centro = _mapController.camera.center;
    setState(() => _zoomActual = nuevoZoom);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(centro, nuevoZoom);
    });
  }

  void _moverCentroMapa({double dLat = 0, double dLon = 0}) {
    final centroActual = _mapController.camera.center;
    final nuevoCentro = LatLng(
      centroActual.latitude + dLat,
      centroActual.longitude + dLon,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapController.move(nuevoCentro, _zoomActual);
    });
  }

  // --------------------------------------------------------- API REST
  Future<void> _solicitarAuxilio() async {
    if (!_gpsActive) {
      setState(() => _respuesta = AuxilioRespuesta.gpsApagado());
      return;
    }

    setState(() {
      _submitting = true;
      _respuesta = null;
    });

    final referencia = _referenciaController.text.trim();
    try {
      final creado = await ApiService.solicitarAuxilio(
        latitud: _rider.latitude,
        longitud: _rider.longitude,
        tipoFalla: _falla,
        referencia: referencia.isEmpty ? null : referencia,
      );
      if (!mounted) return;
      setState(() {
        _auxilio = creado;
        _respuesta = AuxilioRespuesta.creado(creado.idAuxilio);
      });
    } catch (e) {
      if (mounted) {
        setState(() => _respuesta = AuxilioRespuesta.desdeError(e));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _avanzarEstado() async {
    final actual = _auxilio;
    if (actual == null) return;
    final index = _indiceEstado(actual.estadoAuxilio);
    if (index >= AuxilioConfig.estados.length - 1) return;
    final siguiente = AuxilioConfig.estados[index + 1];

    setState(() {
      _advancing = true;
      _respuesta = null;
    });
    try {
      final actualizado = await ApiService.actualizarAuxilio(
        actual.idAuxilio,
        siguiente,
      );
      if (!mounted) return;
      setState(() {
        _auxilio = actualizado;
        _respuesta = AuxilioRespuesta.actualizado(siguiente);
      });
    } catch (e) {
      if (mounted) {
        setState(() => _respuesta = AuxilioRespuesta.desdeError(e));
      }
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  // --------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    final nombre = ApiService.usuarioActual?.nombre ?? 'Conductor';
    return Scaffold(
      appBar: AppBar(title: const Text('Pedir auxilio mecánico')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Hola, $nombre',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _tarjetaGps(),
              const SizedBox(height: 12),
              _tarjetaMapa(),
              const SizedBox(height: 8),
              _botonesZoomYMovimiento(),
              const SizedBox(height: 12),
              _filaDistancia(),
              const SizedBox(height: 16),
              _formulario(),
              const SizedBox(height: 12),
              _tarjetaRespuesta(),
              if (_auxilio != null) ...<Widget>[
                const SizedBox(height: 12),
                _tarjetaSeguimiento(_auxilio!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaGps() {
    final subtitle = _locating
        ? 'Obteniendo ubicación…'
        : _gpsError ??
            (_modoSimulacion
                ? 'Ubicación ajustada en el mapa (simulación)'
                : 'Ubicación del dispositivo (geolocator)');
    return Card(
      child: SwitchListTile(
        secondary: Icon(
          _gpsActive ? Icons.gps_fixed : Icons.gps_off,
          color: _gpsActive ? AppTheme.confirmGreen : AppTheme.alertRed,
        ),
        title: Text('GPS ${_gpsActive ? "Activo" : "Desactivado"}'),
        subtitle: Text(subtitle),
        value: _gpsActive,
        onChanged: (activo) => activo ? _iniciarGps() : _detenerGps(),
      ),
    );
  }

  Widget _tarjetaMapa() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: 290,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                if (_submitting || _advancing) return;
                final punto = _mapController.camera.screenOffsetToLatLng(
                  details.localPosition,
                );
                _moverRider(punto);
              },
              child: IgnorePointer(
                child: FlutterMap(
                  key: const ValueKey('mapa_auxilio_fijo'),
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: _taller,
                    initialZoom: 14.5,
                    minZoom: 11,
                    maxZoom: 18,
                  ),
                  children: <Widget>[
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.leondejuda.app',
                      maxNativeZoom: 19,
                    ),
                    PolylineLayer(
                      polylines: <Polyline>[
                        Polyline(
                          points: <LatLng>[_taller, _rider],
                          color: _enCobertura
                              ? AppTheme.confirmGreen
                              : AppTheme.alertRed,
                          strokeWidth: 2.5,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: <Marker>[_marcadorTaller(), _marcadorRider()],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: const Text(
              'Toca cualquier punto del mapa o usa los botones · © OpenStreetMap contributors',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonesZoomYMovimiento() {
    const paso = 0.008;
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _ajustarZoom(0.8),
                icon: const Icon(Icons.zoom_in),
                label: const Text('Acercar mapa'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _ajustarZoom(-0.8),
                icon: const Icon(Icons.zoom_out),
                label: const Text('Alejar mapa'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: <Widget>[
            OutlinedButton(
              onPressed: () => _moverCentroMapa(dLat: paso),
              child: const Text('↑ Norte'),
            ),
            OutlinedButton(
              onPressed: () => _moverCentroMapa(dLat: -paso),
              child: const Text('↓ Sur'),
            ),
            OutlinedButton(
              onPressed: () => _moverCentroMapa(dLon: -paso),
              child: const Text('← Oeste'),
            ),
            OutlinedButton(
              onPressed: () => _moverCentroMapa(dLon: paso),
              child: const Text('→ Este'),
            ),
          ],
        ),
      ],
    );
  }

  Marker _marcadorTaller() => Marker(
        point: _taller,
        width: 40,
        height: 40,
        child: const CircleAvatar(
          radius: 18,
          backgroundColor: AppTheme.primaryAmber,
          child: Text(
            'T',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

  Marker _marcadorRider() => Marker(
        point: _rider,
        width: 44,
        height: 44,
        child: const CircleAvatar(
          radius: 18,
          backgroundColor: AppTheme.confirmGreen,
          child: Icon(Icons.two_wheeler, color: Colors.white, size: 20),
        ),
      );

  Widget _filaDistancia() => Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'Distancia (Haversine): ${_distanciaKm.toStringAsFixed(2)} km',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _enCobertura ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              _enCobertura ? 'Dentro de cobertura' : 'Fuera de cobertura',
              style: TextStyle(
                fontSize: 12,
                color: _enCobertura ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
          ),
        ],
      );

  Widget _formulario() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DropdownButtonFormField<String>(
            initialValue: _falla,
            decoration: const InputDecoration(
              labelText: '¿Qué le pasó a tu vehículo?',
            ),
            items: AuxilioConfig.fallas
                .map(
                  (falla) => DropdownMenuItem<String>(
                    value: falla,
                    child: Text(falla),
                  ),
                )
                .toList(),
            onChanged: (valor) => setState(() => _falla = valor ?? _falla),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _referenciaController,
            decoration: const InputDecoration(
              labelText: 'Referencia (opcional)',
              hintText: 'Frente al paradero principal',
            ),
          ),
          const SizedBox(height: 12),
          if (!_gpsActive)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '⚠ GPS desactivado: activa la ubicación para poder solicitar auxilio.',
                style: TextStyle(color: AppTheme.alertRed),
              ),
            ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alertRed,
              foregroundColor: Colors.white,
            ),
            onPressed: _submitting ? null : _solicitarAuxilio,
            icon: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.warning_amber_rounded),
            label: Text(_submitting ? 'Enviando…' : '🚨 Solicitar auxilio'),
          ),
        ],
      );

  Widget _tarjetaRespuesta() {
    final respuesta = _respuesta;
    if (respuesta == null) return const SizedBox.shrink();
    return Card(
      color: respuesta.esError ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              respuesta.codigo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: respuesta.esError
                    ? AppTheme.alertRed
                    : AppTheme.confirmGreen,
              ),
            ),
            const SizedBox(height: 4),
            Text(respuesta.mensaje),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaSeguimiento(Auxilio auxilio) {
    final index = _indiceEstado(auxilio.estadoAuxilio);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Auxilio #${auxilio.idAuxilio} · ${auxilio.tipoFalla}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (index + 1) / AuxilioConfig.estados.length,
              minHeight: 8,
              color: AppTheme.primaryAmber,
            ),
            const SizedBox(height: 8),
            Row(
              children: AuxilioConfig.estados.map((estado) {
                final i = AuxilioConfig.estados.indexOf(estado);
                return Expanded(
                  child: Text(
                    estado,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          i <= index ? FontWeight.bold : FontWeight.normal,
                      color: i <= index ? Colors.orange.shade900 : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              'A ${auxilio.distanciaKm.toStringAsFixed(2)} km del taller · '
              'llegada estimada ${_minutosEstimados(auxilio.distanciaKm)} min',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            if (_auxilioActivo) ...<Widget>[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _advancing ? null : _avanzarEstado,
                icon: _advancing
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
                label: const Text('Simular avance del mecánico (PATCH)'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _minutosEstimados(double km) =>
      km <= 0 ? 1 : (km / 15 * 60).round().clamp(1, 999);
}