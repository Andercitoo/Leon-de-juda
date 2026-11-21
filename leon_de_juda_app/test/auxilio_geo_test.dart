import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:leon_de_juda_app/config/auxilio_config.dart';
import 'package:leon_de_juda_app/utils/auxilio_geo.dart';

void main() {
  const taller = LatLng(AuxilioConfig.tallerLat, AuxilioConfig.tallerLon);

  test('distancia al taller es cero', () {
    expect(distanciaEntre(taller, taller), closeTo(0, 0.0001));
  });

  test('simulación a 2 km está dentro de cobertura', () {
    final punto = puntoDestino(
      origen: taller,
      distanciaKm: 2,
      rumboGrados: 90,
    );
    expect(distanciaEntre(taller, punto), closeTo(2, 0.01));
    expect(distanciaEntre(taller, punto),
        lessThanOrEqualTo(AuxilioConfig.radioKm));
  });

  test('simulación a 5.2 km está fuera de cobertura', () {
    final punto = puntoDestino(
      origen: taller,
      distanciaKm: 5.2,
      rumboGrados: 90,
    );
    expect(distanciaEntre(taller, punto), closeTo(5.2, 0.01));
    expect(distanciaEntre(taller, punto), greaterThan(AuxilioConfig.radioKm));
  });

  test('rumbo norte aumenta la latitud', () {
    final punto = puntoDestino(
      origen: taller,
      distanciaKm: 1,
      rumboGrados: 0,
    );
    expect(punto.latitude, greaterThan(taller.latitude));
    expect(punto.longitude, closeTo(taller.longitude, 0.00001));
  });
}
