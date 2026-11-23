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
    'Acelerador',
    'Eléctrico',
    'Suspensión',
    'Llantas',
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
        error =
            'No se pudo cargar el catálogo.\n'
            'Verifica que el servidor Node.js esté encendido en el puerto 3000.\n\n$e';
      });
    }
  }

  List<Repuesto> get repuestosFiltrados {
    final q = textoBusqueda.trim().toLowerCase();
    return repuestos.where((r) {
      final okMarca =
          marcaSeleccionada == 'Todas' || r.marca == marcaSeleccionada;
      final okCategoria =
          categoriaSeleccionada == 'Todas' ||
          r.categoriaAveria == categoriaSeleccionada;
      final okNombre = q.isEmpty || r.nombre.toLowerCase().contains(q);
      return okMarca && okCategoria && okNombre;
    }).toList();
  }

  void agregarAlCarrito(Repuesto repuesto) {
    final agregado = carrito.agregar(repuesto);
    AppTheme.tap();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          agregado
              ? '${repuesto.nombre} agregado al carrito'
              : 'No hay más stock disponible de ${repuesto.nombre}',
        ),
        backgroundColor: agregado ? AppTheme.confirmGreen : AppTheme.alertRed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void irAlCarrito() {
    AppTheme.tap();
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
        centerTitle: true,
        title: const Text('Catálogo'),
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.backgroundSand, Color(0xFFFFF3E2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: TextField(
                controller: buscadorController,
                decoration: InputDecoration(
                  hintText: 'Busca una pieza para tu ruta',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.brandRed,
                  ),
                  isDense: true,
                  suffixIcon: textoBusqueda.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            AppTheme.tap();
                            buscadorController.clear();
                            setState(() => textoBusqueda = '');
                          },
                        ),
                ),
                onChanged: (v) => setState(() => textoBusqueda = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Card(
                elevation: 1,
                shadowColor: AppTheme.brandRed.withValues(alpha: 0.08),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: AppTheme.primaryAmber.withValues(alpha: 0.12),
                  ),
                  child: ExpansionTile(
                    shape: const RoundedRectangleBorder(),
                    leading: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: AppTheme.amberGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tune, color: AppTheme.darkText),
                    ),
                    title: const Text(
                      'Filtrar piezas',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '$marcaSeleccionada · $categoriaSeleccionada',
                      style: const TextStyle(color: AppTheme.mutedText),
                    ),
                    onExpansionChanged: (_) => AppTheme.tap(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MARCA',
                              style: TextStyle(
                                color: AppTheme.brandRed,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                fontSize: 11,
                              ),
                            ),
                            buildFilaChips(
                              opciones: marcas,
                              seleccionada: marcaSeleccionada,
                              onSeleccionar: (m) {
                                AppTheme.tap();
                                setState(() => marcaSeleccionada = m);
                              },
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'TIPO DE PIEZA',
                              style: TextStyle(
                                color: AppTheme.brandRed,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                fontSize: 11,
                              ),
                            ),
                            buildFilaChips(
                              opciones: categorias,
                              seleccionada: categoriaSeleccionada,
                              onSeleccionar: (c) {
                                AppTheme.tap();
                                setState(() => categoriaSeleccionada = c);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: buildContenido()),
          ],
        ),
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
            selectedColor: AppTheme.amberLight,
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
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.brandRed),
      );
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
                Center(
                  child: Text(
                    'Sin resultados.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            )
          : ListenableBuilder(
              listenable: carrito,
              builder: (context, _) => LayoutBuilder(
                builder: (context, constraints) {
                  const gridPadding = 14.0;
                  const spacing = 12.0;
                  const maxCardWidth = 260.0;
                  final contentWidth = constraints.maxWidth - gridPadding * 2;
                  final crossAxisCount =
                      ((contentWidth + spacing) / (maxCardWidth + spacing))
                          .ceil()
                          .clamp(2, 8)
                          .toInt();
                  final cardWidth =
                      (contentWidth - spacing * (crossAxisCount - 1)) /
                      crossAxisCount;

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      gridPadding,
                      12,
                      gridPadding,
                      24,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      mainAxisExtent: cardWidth + 170,
                    ),
                    itemCount: lista.length,
                    itemBuilder: (context, i) => TweenAnimationBuilder<double>(
                      key: ValueKey(lista[i].idRepuesto),
                      tween: Tween(begin: 0.94, end: 1),
                      duration: Duration(milliseconds: 220 + (i % 5) * 55),
                      curve: Curves.easeOutCubic,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: buildTarjetaRepuesto(lista[i]),
                    ),
                  );
                },
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
      elevation: 2,
      shadowColor: AppTheme.brandRed.withValues(alpha: 0.08),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: AppTheme.tap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: buildImagenRepuesto(r),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        r.marca.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.brandRed,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                r.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  height: 1.15,
                ),
              ),
              Text(
                r.categoriaAveria,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.mutedText, fontSize: 11),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  textoStock,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorStock,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text(
                    'S/ ${r.precioUnitario.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.brandRed,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: (agotado || restante <= 0)
                      ? null
                      : () => agregarAlCarrito(r),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandRed,
                    disabledBackgroundColor: const Color(0xFFE7D9D4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  icon: const Icon(Icons.add_shopping_cart, size: 15),
                  label: const Text('Agregar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildImagenRepuesto(Repuesto repuesto) {
    final nombre = repuesto.nombre.toLowerCase();
    final String? asset;
    if (nombre.contains('pastilla') || nombre.contains('zapata')) {
      asset = 'assets/images/brake_pads.jpg';
    } else if (nombre.contains('cadena')) {
      asset = 'assets/images/transmission_chain.jpg';
    } else if (nombre.contains('embrague')) {
      asset = 'assets/images/clutch_discs.jpg';
    } else if (nombre.contains('buj')) {
      asset = 'assets/images/motor_engine.jpg';
    } else if (nombre.contains('filtro')) {
      asset = 'assets/images/air_filter.jpg';
    } else if (nombre.contains('faro')) {
      asset = 'assets/images/headlight.jpg';
    } else if (nombre.contains('bater')) {
      asset = 'assets/images/battery.jpg';
    } else if (nombre.contains('llanta')) {
      asset = 'assets/images/tire.jpg';
    } else {
      asset = null;
    }

    if (asset == null) {
      return _imagenAlternativa();
    }
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _imagenAlternativa(),
    );
  }

  Widget _imagenAlternativa() {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.amberGradient),
      child: const Center(
        child: Icon(
          Icons.settings_outlined,
          size: 48,
          color: AppTheme.brandRed,
        ),
      ),
    );
  }
}
