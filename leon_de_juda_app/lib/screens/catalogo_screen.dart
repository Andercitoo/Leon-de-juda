import 'package:flutter/material.dart';
import '../models/repuesto.dart';
import '../services/api_service.dart';
import '../services/carrito_service.dart';
import '../theme/app_theme.dart';
import 'carrito_screen.dart';

/// catView del prototipo HTML: catálogo con buscador y filtros por marca/categoría.
/// Consume GET /api/repuestos (PostgreSQL).
class CatalogoScreen extends StatefulWidget {
  /// Si se usa dentro de la barra inferior (MainNavScreen), pasar un callback
  /// que cambie a la pestaña Carrito. Si es null, se abre CarritoScreen con push.
  final VoidCallback? onIrAlCarrito;

  const CatalogoScreen({super.key, this.onIrAlCarrito});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  static const List<String> marcas = ['Todas', 'Bajaj', 'TVS'];
  static const List<String> categorias = [
    'Todas',
    'Frenos',
    'Motor',
    'Transmisión',
    'Eléctrico',
    'Suspensión',
  ];

  final CarritoService carrito = CarritoService.instancia;
  final TextEditingController buscadorController = TextEditingController();

  List<Repuesto> repuestos = [];
  bool cargando = true;
  String? error;
  String marcaSeleccionada = 'Todas';
  String categoriaSeleccionada = 'Todas';
  String textoBusqueda = '';

  @override
  void initState() {
    super.initState();
    cargarRepuestos();
  }

  @override
  void dispose() {
    buscadorController.dispose();
    super.dispose();
  }

  Future<void> cargarRepuestos() async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      final lista = await ApiService.getRepuestos();
      if (!mounted) return;
      carrito.sincronizarStock(lista);
      setState(() {
        repuestos = lista;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        cargando = false;
        error = 'No se pudo cargar el catálogo.\n'
            'Verifica que el servidor Node.js esté encendido en el puerto 3000.\n\n$e';
      });
    }
  }

  List<Repuesto> get repuestosFiltrados {
    final q = textoBusqueda.trim().toLowerCase();
    return repuestos.where((r) {
      final okMarca = marcaSeleccionada == 'Todas' || r.marca == marcaSeleccionada;
      final okCategoria =
          categoriaSeleccionada == 'Todas' || r.categoriaAveria == categoriaSeleccionada;
      final okNombre = q.isEmpty || r.nombre.toLowerCase().contains(q);
      return okMarca && okCategoria && okNombre;
    }).toList();
  }

  void agregarAlCarrito(Repuesto repuesto) {
    final agregado = carrito.agregar(repuesto);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(agregado
            ? '${repuesto.nombre} agregado al carrito'
            : 'No hay más stock disponible de ${repuesto.nombre}'),
        backgroundColor: agregado ? AppTheme.confirmGreen : AppTheme.alertRed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void irAlCarrito() {
    if (widget.onIrAlCarrito != null) {
      widget.onIrAlCarrito!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CarritoScreen()),
      ).then((_) => cargarRepuestos());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          ListenableBuilder(
            listenable: carrito,
            builder: (context, _) => IconButton(
              tooltip: 'Ver carrito',
              onPressed: irAlCarrito,
              icon: Badge(
                isLabelVisible: carrito.totalUnidades > 0,
                backgroundColor: AppTheme.alertRed,
                label: Text('${carrito.totalUnidades}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
            child: TextField(
              controller: buscadorController,
              decoration: InputDecoration(
                hintText: 'Buscar repuesto…',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: textoBusqueda.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          buscadorController.clear();
                          setState(() => textoBusqueda = '');
                        },
                      ),
              ),
              onChanged: (v) => setState(() => textoBusqueda = v),
            ),
          ),
          buildFilaChips(
            opciones: marcas,
            seleccionada: marcaSeleccionada,
            onSeleccionar: (m) => setState(() => marcaSeleccionada = m),
          ),
          buildFilaChips(
            opciones: categorias,
            seleccionada: categoriaSeleccionada,
            onSeleccionar: (c) => setState(() => categoriaSeleccionada = c),
          ),
          const SizedBox(height: 4),
          Expanded(child: buildContenido()),
        ],
      ),
    );
  }

  Widget buildFilaChips({
    required List<String> opciones,
    required String seleccionada,
    required ValueChanged<String> onSeleccionar,
  }) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        itemCount: opciones.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final opcion = opciones[i];
          final activo = opcion == seleccionada;
          return ChoiceChip(
            label: Text(opcion),
            selected: activo,
            showCheckmark: false,
            onSelected: (_) => onSeleccionar(opcion),
            selectedColor: AppTheme.primaryAmber,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: activo ? const Color(0xFF1A1200) : AppTheme.darkText,
              fontWeight: activo ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(99),
              side: BorderSide(
                color: activo ? AppTheme.primaryAmber : const Color(0xFFE3DDCF),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildContenido() {
    if (cargando) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryAmber));
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppTheme.alertRed),
              const SizedBox(height: 12),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: cargarRepuestos,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final lista = repuestosFiltrados;
    return RefreshIndicator(
      color: AppTheme.primaryAmber,
      onRefresh: cargarRepuestos,
      child: lista.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 60),
                Center(child: Text('Sin resultados.', style: TextStyle(color: Colors.grey))),
              ],
            )
          : ListenableBuilder(
              listenable: carrito,
              builder: (context, _) => ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                itemCount: lista.length,
                itemBuilder: (context, i) => buildTarjetaRepuesto(lista[i]),
              ),
            ),
    );
  }

  Widget buildTarjetaRepuesto(Repuesto r) {
    final enCarrito = carrito.cantidadDe(r.idRepuesto);
    final restante = r.stockDisponible - enCarrito;
    final agotado = r.stockDisponible <= 0;

    final String textoStock;
    final Color colorStock;
    if (agotado) {
      textoStock = 'Agotado';
      colorStock = AppTheme.alertRed;
    } else if (r.stockDisponible <= 3) {
      textoStock = r.stockDisponible == 1
          ? 'Última unidad'
          : 'Últimas ${r.stockDisponible} unidades';
      colorStock = const Color(0xFFB26A00);
    } else {
      textoStock = 'Stock: ${r.stockDisponible}';
      colorStock = AppTheme.confirmGreen;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    r.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'S/ ${r.precioUnitario.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${r.marca} · ${r.categoriaAveria}',
              style: const TextStyle(color: Color(0xFF6F6A5E), fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF3DC),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    textoStock,
                    style: TextStyle(fontSize: 12, color: colorStock, fontWeight: FontWeight.w600),
                  ),
                ),
                if (enCarrito > 0) ...[
                  const SizedBox(width: 6),
                  Text('· $enCarrito en carrito',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6F6A5E))),
                ],
                const Spacer(),
                ElevatedButton(
                  onPressed: (agotado || restante <= 0) ? null : () => agregarAlCarrito(r),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    foregroundColor: const Color(0xFF1A1200),
                  ),
                  child: const Text('Agregar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
