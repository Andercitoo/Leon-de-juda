import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _loginDniController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _nameController = TextEditingController();
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _placaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _soatVigente = true;
  bool _ingresando = false;
  bool _registrando = false;

  Future<void> _iniciarSesion() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _ingresando = true);
    try {
      await ApiService.login(
        _loginDniController.text.trim(),
        _loginPasswordController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _ingresando = false);
    }
  }

  Future<void> _registrarUsuario() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _registrando = true);
    try {
      final dni = _dniController.text.trim();
      final password = _passwordController.text;

      await ApiService.registrar(
        dni: dni,
        nombre: _nameController.text.trim(),
        telefono: _telefonoController.text.trim().isEmpty
            ? null
            : _telefonoController.text.trim(),
        placaVehiculo: _placaController.text.trim().toUpperCase(),
        modeloMoto: _modeloController.text.trim().isEmpty
            ? null
            : _modeloController.text.trim(),
        soatVigente: _soatVigente,
        password: password,
      );

      await ApiService.login(dni, password);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _registrando = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginDniController.dispose();
    _loginPasswordController.dispose();
    _nameController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _placaController.dispose();
    _modeloController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('León de Judá'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Iniciar Sesión'),
            Tab(text: 'Registrarse'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLoginForm(),
          _buildRegisterForm(),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.two_wheeler, size: 72, color: AppTheme.primaryAmber),
            const SizedBox(height: 24),
            TextFormField(
              controller: _loginDniController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'DNI',
                prefixIcon: Icon(Icons.badge_outlined),
                counterText: '',
              ),
              validator: (value) => (value == null || !RegExp(r'^\d{8}$').hasMatch(value.trim()))
                  ? 'El DNI debe tener 8 dígitos'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _loginPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) => (value == null || value.length < 6)
                  ? 'La contraseña debe tener al menos 6 caracteres'
                  : null,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _ingresando ? null : _iniciarSesion,
              child: _ingresando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('INGRESAR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Ingresa tu nombre'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dniController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'DNI (8 dígitos)',
                prefixIcon: Icon(Icons.badge_outlined),
                counterText: '',
              ),
              validator: (value) => (value == null || !RegExp(r'^\d{8}$').hasMatch(value.trim()))
                  ? 'El DNI debe tener exactamente 8 dígitos'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonoController,
              keyboardType: TextInputType.phone,
              maxLength: 9,
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
                prefixIcon: Icon(Icons.phone_android),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _placaController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Placa de Vehículo (ej. ABC123)',
                prefixIcon: Icon(Icons.two_wheeler),
                counterText: '',
              ),
              validator: (value) =>
                  (value == null || !RegExp(r'^[A-Z0-9]{6}$', caseSensitive: false).hasMatch(value.trim()))
                      ? 'La placa debe tener 6 caracteres alfanuméricos'
                      : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _modeloController,
              decoration: const InputDecoration(
                labelText: 'Modelo de Mototaxi (ej. Bajaj RE Torito)',
                prefixIcon: Icon(Icons.build_circle_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña (mínimo 6 caracteres)',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) => (value == null || value.length < 6)
                  ? 'Mínimo 6 caracteres'
                  : null,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _soatVigente,
              onChanged: (v) => setState(() => _soatVigente = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: AppTheme.confirmGreen,
              title: const Text('Cuento con SOAT vigente (RN-S01)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _registrando ? null : _registrarUsuario,
              child: _registrando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('REGISTRARSE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}