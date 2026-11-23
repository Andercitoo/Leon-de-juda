import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/carrito_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'auxilio_screen.dart';
import 'carrito_screen.dart';
import 'catalogo_screen.dart';
import 'perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceActual = 0;
  final CarritoService _carrito = CarritoService.instancia;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarPedidos());
  }

  Future<void> _cargarPedidos() async {
    final idUsuario = ApiService.usuarioActual?.idUsuario;
    if (idUsuario == null) return;
    try {
      final pedidos = await ApiService.getPedidos();
      if (!mounted || ApiService.usuarioActual?.idUsuario != idUsuario) return;
      _carrito.cargarPedidos(pedidos);
    } catch (e) {
      if (!mounted || ApiService.usuarioActual?.idUsuario != idUsuario) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cargar el historial de pedidos: $e'),
        ),
      );
    }
  }

  void _cambiarTab(int index) {
    AppTheme.tap();
    setState(() => _indiceActual = index);
  }

  void _cerrarSesion() {
    _carrito.limpiarSesion();
    ApiService.cerrarSesion();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pantallas = [
      _buildInicioTab(),
      CatalogoScreen(onIrAlCarrito: () => _cambiarTab(3)),
      const AuxilioScreen(),
      CarritoScreen(onIrAlCatalogo: () => _cambiarTab(1)),
      ListenableBuilder(
        listenable: _carrito,
        builder: (context, _) => PerfilScreen(
          usuario: ApiService.usuarioActual,
          historialPedidos: _carrito.pedidosRealizados,
          onCerrarSesion: _cerrarSesion,
        ),
      ),
    ];

    return Scaffold(
      body: pantallas[_indiceActual],
      bottomNavigationBar: ListenableBuilder(
        listenable: _carrito,
        builder: (context, _) => BottomNavigationBar(
          currentIndex: _indiceActual,
          onTap: _cambiarTab,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.brandRed,
          unselectedItemColor: Colors.grey.shade600,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.build_outlined),
              activeIcon: Icon(Icons.build),
              label: 'Catálogo',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              activeIcon: Icon(Icons.location_on),
              label: 'Auxilio',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: _carrito.totalUnidades > 0,
                backgroundColor: AppTheme.alertRed,
                label: Text('${_carrito.totalUnidades}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              activeIcon: Badge(
                isLabelVisible: _carrito.totalUnidades > 0,
                backgroundColor: AppTheme.alertRed,
                label: Text('${_carrito.totalUnidades}'),
                child: const Icon(Icons.shopping_cart),
              ),
              label: 'Carrito',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInicioTab() {
    final usuario = ApiService.usuarioActual;
    final nombre = usuario?.nombre ?? 'Conductor';
    final placa = usuario?.placaVehiculo;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              AppTheme.tap();
              _cerrarSesion();
            },
          ),
        ],
      ),
      body: AppPageBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWelcomeCard(nombre, placa),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _buildServiceCard(
                        icon: Icons.build_rounded,
                        title: 'Catálogo',
                        selected: _indiceActual == 1,
                        onTap: () => _cambiarTab(1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildServiceCard(
                        icon: Icons.support_agent_rounded,
                        title: 'Auxilio',
                        selected: _indiceActual == 2,
                        onTap: () => _cambiarTab(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildServiceCard(
                        icon: Icons.shopping_bag_rounded,
                        title: 'Carrito',
                        selected: _indiceActual == 3,
                        onTap: () => _cambiarTab(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildServiceCard(
                        icon: Icons.person_rounded,
                        title: 'Perfil',
                        selected: _indiceActual == 4,
                        onTap: () => _cambiarTab(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const Text(
                  'Novedades',
                  style: TextStyle(
                    color: AppTheme.darkText,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                _buildNewsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String nombre, String? placa) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADBD0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Hola, $nombre!',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.brandRed,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            placa != null && placa.isNotEmpty
                ? 'Vehículo · $placa'
                : 'Repuestos y auxilio mecánico',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.darkText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: title,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
                child: AnimatedScale(
                  scale: selected ? 1.05 : 1,
                duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFB88A3A),
                        width: selected ? 2 : 1,
                    ),
                    ),
                    alignment: Alignment.center,
                    child: ShaderMask(
                      shaderCallback: AppTheme.amberGradient.createShader,
                      blendMode: BlendMode.srcIn,
                      child: Icon(
                        icon,
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                ),
              ),
            ),
          ),
            const SizedBox(height: 7),
          Text(
            title,
            textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
                fontSize: 10,
                height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard() {
    const months = [
        'ene',
        'feb',
        'mar',
        'abr',
        'may',
        'jun',
        'jul',
        'ago',
        'sep',
        'oct',
        'nov',
        'dic',
    ];
    final now = DateTime.now();
    final date = '${now.day} ${months[now.month - 1]} ${now.year}';

    return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/air_filter.jpg',
                  width: 104,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        color: AppTheme.brandRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Cuida el motor en cada ruta',
                      style: TextStyle(
                        color: AppTheme.darkText,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Revisa el filtro de aire con regularidad para mantener tu mototaxi en buen estado.',
                      style: TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}
