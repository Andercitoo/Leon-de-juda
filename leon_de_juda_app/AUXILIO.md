# Módulo de auxilio (Yupanqui)

Pantalla: `lib/screens/auxilio_screen.dart` (`auxView` del prototipo HTML).

## Archivos propios del módulo

- `lib/config/auxilio_config.dart` — taller `(-12.215840, -76.931420)`,
  radio `3.50 km`, fallas y estados.
- `lib/utils/auxilio_geo.dart` — Haversine y punto de simulación.
- `lib/services/auxilio_respuesta.dart` — tarjetas 201/422/409/400/401.
- `test/auxilio_geo_test.dart`, `test/auxilio_respuesta_test.dart`.

## Integración

La pantalla usa el `ApiService` del equipo, cuya URL base es
`http://10.0.2.2:3000/api` (Ya definida en `develop`). No requiere parámetros:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const AuxilioScreen()),
);
```

La navegación desde `home_screen.dart` / `main_nav_screen.dart` corresponde al
módulo de Erick.

## Demo en emulador

1. GPS apagado → "Solicitar auxilio" → tarjeta `400 · RN-R02`.
2. GPS activo + "Simular a 2 km" → `201 Created` y barra `Pendiente`.
3. "Simular avance del mecánico (PATCH)" → `En camino` → `Finalizado`.
4. "Simular a 5.2 km" → `422 · RN-R01`.
5. Con un auxilio activo en BD → `409 · RN-R03`.

> El `seed.sql` deja un auxilio `En camino`; para ver el `201` hay que
> finalizarlo antes:
> `UPDATE auxilio_mecanico SET estado_auxilio='Finalizado' WHERE estado_auxilio='En camino';`

## Verificación del módulo

```powershell
flutter analyze lib/screens/auxilio_screen.dart lib/config/auxilio_config.dart lib/utils/auxilio_geo.dart lib/services/auxilio_respuesta.dart
flutter test test/auxilio_geo_test.dart test/auxilio_respuesta_test.dart
```
