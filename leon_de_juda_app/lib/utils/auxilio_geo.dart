import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Radio medio de la Tierra en kilómetros.
const double kAuxilioEarthRadiusKm = 6371.0088;

/// Distancia Haversine entre dos coordenadas, en kilómetros.
double distanciaHaversineKm(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  final toRad = math.pi / 180.0;
  final dLat = (lat2 - lat1) * toRad;
  final dLon = (lon2 - lon1) * toRad;
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1 * toRad) *
          math.cos(lat2 * toRad) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * kAuxilioEarthRadiusKm * math.asin(math.sqrt(a));
}

/// Distancia entre dos [LatLng] en kilómetros.
double distanciaEntre(LatLng desde, LatLng hasta) => distanciaHaversineKm(
      desde.latitude,
      desde.longitude,
      hasta.latitude,
      hasta.longitude,
    );

/// Punto resultante de avanzar [distanciaKm] desde [origen] con rumbo
/// [rumboGrados] (0 = norte, 90 = este).
///
/// Se usa para los botones "Simular a 2 km" y "Simular a 5.2 km".
LatLng puntoDestino({
  required LatLng origen,
  required double distanciaKm,
  required double rumboGrados,
}) {
  final toRad = math.pi / 180.0;
  final toDeg = 180.0 / math.pi;
  final angular = distanciaKm / kAuxilioEarthRadiusKm;
  final rumbo = rumboGrados * toRad;
  final lat1 = origen.latitude * toRad;
  final lon1 = origen.longitude * toRad;

  final lat2 = math.asin(
    math.sin(lat1) * math.cos(angular) +
        math.cos(lat1) * math.sin(angular) * math.cos(rumbo),
  );
  final lon2 = lon1 +
      math.atan2(
        math.sin(rumbo) * math.sin(angular) * math.cos(lat1),
        math.cos(angular) - math.sin(lat1) * math.sin(lat2),
      );

  return LatLng(lat2 * toDeg, lon2 * toDeg);
}
