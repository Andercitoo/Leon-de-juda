import 'package:flutter_test/flutter_test.dart';

import 'package:leon_de_juda_app/services/auxilio_respuesta.dart';

void main() {
  test('201 Created muestra el id del auxilio', () {
    final respuesta = AuxilioRespuesta.creado(17);
    expect(respuesta.codigo, '201 Created');
    expect(respuesta.mensaje, contains('#17'));
    expect(respuesta.esError, isFalse);
  });

  test('RN-R01 se convierte en 422 Unprocessable', () {
    final respuesta = AuxilioRespuesta.desdeError(
      Exception(
        'RN-R01: Fuera de rango (5.20 km). Radio máximo: 3.5 km.',
      ),
    );
    expect(respuesta.codigo, '422 Unprocessable Entity');
    expect(respuesta.mensaje, contains('RN-R01'));
    expect(respuesta.esError, isTrue);
  });

  test('RN-R03 se convierte en 409 Conflict', () {
    final respuesta = AuxilioRespuesta.desdeError(
      Exception('RN-R03: El mecánico ya se encuentra en ruta para otro auxilio.'),
    );
    expect(respuesta.codigo, '409 Conflict');
    expect(respuesta.mensaje, contains('RN-R03'));
  });

  test('falta de token se convierte en 401', () {
    final respuesta = AuxilioRespuesta.desdeError(
      Exception('Token de acceso no proporcionado.'),
    );
    expect(respuesta.codigo, '401 Unauthorized');
  });

  test('GPS apagado muestra RN-R02', () {
    final respuesta = AuxilioRespuesta.gpsApagado();
    expect(respuesta.codigo, '400 Bad Request');
    expect(respuesta.mensaje, contains('RN-R02'));
  });
}
