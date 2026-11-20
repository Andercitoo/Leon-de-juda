const AuxilioModel = require('../models/auxilioModel');
const calcularDistanciaHaversine = require('../utils/haversine');

const TALLER_LAT = parseFloat(process.env.TALLER_LAT_ORIGEN);
const TALLER_LON = parseFloat(process.env.TALLER_LON_ORIGEN);
const RADIO_MAX = parseFloat(process.env.RADIO_MAX_KM);

exports.solicitarAuxilio = async (req, res) => {
  try {
    const { latitud, longitud, tipo_falla, referencia } = req.body;
    const id_usuario = req.user.id_usuario;

    if (latitud === undefined || longitud === undefined || latitud === null || longitud === null) {
      return res.status(400).json({ error: 'RN-R02: Debe enviar las coordenadas GPS.' });
    }

    const lat = parseFloat(latitud);
    const lon = parseFloat(longitud);

    const distancia = calcularDistanciaHaversine(TALLER_LAT, TALLER_LON, lat, lon);
    if (distancia > RADIO_MAX) {
      return res.status(422).json({
        error: `RN-R01: Fuera de rango (${distancia.toFixed(2)} km). Radio máximo: ${RADIO_MAX} km.`
      });
    }

    const auxiliosActivos = await AuxilioModel.countActivos();
    if (auxiliosActivos >= 1) {
      return res.status(409).json({
        error: 'RN-R03: El mecánico ya se encuentra en ruta para otro auxilio.'
      });
    }

    const nuevoAuxilio = await AuxilioModel.create({
      id_usuario,
      latitud: lat,
      longitud: lon,
      distancia_km: parseFloat(distancia.toFixed(2)),
      tipo_falla: tipo_falla || 'Falla no especificada',
      referencia: referencia || null
    });

    return res.status(201).json({
      mensaje: 'Auxilio mecánico asignado con éxito.',
      auxilio: nuevoAuxilio
    });
  } catch (error) {
    console.error('Error en auxilio:', error);
    return res.status(500).json({ error: 'Error interno al registrar auxilio.' });
  }
};

exports.actualizarEstado = async (req, res) => {
  try {
    const { id } = req.params;
    const { estado } = req.body;

    const estadosValidos = ['Pendiente', 'En camino', 'Finalizado'];
    if (!estadosValidos.includes(estado)) {
      return res.status(400).json({ error: `Estado no válido. Use: ${estadosValidos.join(', ')}` });
    }

    const auxilioActualizado = await AuxilioModel.updateEstado(id, estado);
    if (!auxilioActualizado) {
      return res.status(404).json({ error: 'Auxilio no encontrado.' });
    }

    return res.status(200).json({
      mensaje: 'Estado actualizado correctamente.',
      auxilio: auxilioActualizado
    });
  } catch (error) {
    console.error('Error al actualizar estado:', error);
    return res.status(500).json({ error: 'Error interno en el servidor.' });
  }
};