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

  void _cambiarTab(int index) {
    setState(() => _indiceActual = index);
  }

  void _cerrarSesion() {
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
          historialPedidos: _carrito.pedidoReservado != null
              ? [_carrito.pedidoReservado!]
              : const [],
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
          selectedItemColor: AppTheme.primaryAmber,
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
        title: const Text('León de Judá - Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppTheme.primaryAmber,
                      radius: 28,
                      child: Icon(Icons.two_wheeler, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Bienvenido, $nombre!',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            placa != null && placa.isNotEmpty
                                ? 'Vehículo registrado: $placa'
                                : 'Panel de repuestos y auxilio mecánico',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Servicios Disponibles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildServiceCard(
                    icon: Icons.build_outlined,
                    title: 'Comprar repuesto',
                    color: AppTheme.primaryAmber,
                    onTap: () => _cambiarTab(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildServiceCard(
                    icon: Icons.sos_outlined,
                    title: 'Auxilio mecánico',
                    color: AppTheme.alertRed,
                    onTap: () => _cambiarTab(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildServiceCard(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Mi Carrito',
                    color: Colors.blue.shade700,
                    onTap: () => _cambiarTab(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildServiceCard(
                    icon: Icons.badge_outlined,
                    title: 'Mi Perfil',
                    color: AppTheme.confirmGreen,
                    onTap: () => _cambiarTab(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22.0, horizontal: 12.0),
          child: Column(
            children: [
              Icon(icon, size: 38, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}