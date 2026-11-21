/// Tarjeta de respuesta mostrada en la pantalla de auxilio.
///
/// El equipo usa un `ApiService` estático que lanza `Exception` con el mensaje
/// del servidor. Este helper convierte ese mensaje al código HTTP que exige el
/// prototipo (201 / 422 / 409 ...) sin depender de implementaciones ajenas.
class AuxilioRespuesta {
  final String codigo;
  final String mensaje;
  final bool esError;

  const AuxilioRespuesta({
    required this.codigo,
    required this.mensaje,
    required this.esError,
  });

  factory AuxilioRespuesta.creado(int id) => AuxilioRespuesta(
        codigo: '201 Created',
        mensaje: 'Auxilio #$id registrado y asignado al mecánico de turno.',
        esError: false,
      );

  factory AuxilioRespuesta.actualizado(String estado) => AuxilioRespuesta(
        codigo: '200 OK',
        mensaje: 'Estado actualizado correctamente a "$estado".',
        esError: false,
      );

  factory AuxilioRespuesta.gpsApagado() => const AuxilioRespuesta(
        codigo: '400 Bad Request',
        mensaje: 'RN-R02: activa tu ubicación GPS para pedir auxilio.',
        esError: true,
      );

  factory AuxilioRespuesta.desdeError(Object error) {
    final texto = error
        .toString()
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .trim();
    final lower = texto.toLowerCase();
    final match = RegExp(r'\((\d{3})\)').firstMatch(texto);
    final status = match == null ? null : int.tryParse(match.group(1)!);

    if (texto.contains('RN-R01') ||
        lower.contains('fuera de rango') ||
        status == 422) {
      return AuxilioRespuesta(
        codigo: '422 Unprocessable Entity',
        mensaje: texto.isEmpty
            ? 'RN-R01: Fuera de cobertura. Radio máximo 3.50 km.'
            : texto,
        esError: true,
      );
    }
    if (texto.contains('RN-R03') ||
        lower.contains('mecánico') ||
        status == 409) {
      return AuxilioRespuesta(
        codigo: '409 Conflict',
        mensaje: texto.isEmpty
            ? 'RN-R03: el mecánico ya se encuentra en ruta.'
            : texto,
        esError: true,
      );
    }
    if (texto.contains('RN-R02') || status == 400) {
      return AuxilioRespuesta(
        codigo: '400 Bad Request',
        mensaje: texto.isEmpty ? 'Solicitud inválida.' : texto,
        esError: true,
      );
    }
    if (lower.contains('token') || status == 401 || status == 403) {
      return AuxilioRespuesta(
        codigo: status == 403 ? '403 Forbidden' : '401 Unauthorized',
        mensaje: texto.isEmpty
            ? 'Sesión expirada. Vuelve a iniciar sesión.'
            : texto,
        esError: true,
      );
    }
    return AuxilioRespuesta(
      codigo: status == null ? '500 Internal Server Error' : '$status Error',
      mensaje: texto.isEmpty ? 'Error interno del servidor.' : texto,
      esError: true,
    );
  }
}
