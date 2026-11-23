import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
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
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.backgroundSand, Color(0xFFFFF3E2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 34, 20, 14),
                  child: Text(
                    'León de Judá',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.brandRed,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEFE1D6)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      onTap: (_) => AppTheme.tap(),
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        gradient: AppTheme.brandGradient,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppTheme.mutedText,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(text: 'Iniciar sesión'),
                        Tab(text: 'Crear cuenta'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildLoginForm(), _buildRegisterForm()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 26),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(2, 0, 2, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qué bueno verte.',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.darkText,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ingresa para continuar tu camino.',
                    style: TextStyle(color: AppTheme.mutedText, fontSize: 13),
                  ),
                ],
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _loginDniController,
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      decoration: const InputDecoration(
                        labelText: 'DNI',
                        prefixIcon: Icon(Icons.badge_outlined),
                        counterText: '',
                      ),
                      validator: (value) =>
                          (value == null ||
                              !RegExp(r'^\d{8}$').hasMatch(value.trim()))
                          ? 'El DNI debe tener 8 dígitos'
                          : null,
                    ),
                    const SizedBox(height: 13),
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
                    const SizedBox(height: 22),
                    _botonPrincipal(
                      texto: 'INGRESAR',
                      cargando: _ingresando,
                      onPressed: _iniciarSesion,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonPrincipal({
    required String texto,
    required bool cargando,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandRed.withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: cargando
              ? null
              : () {
                  AppTheme.tap();
                  onPressed();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: AppTheme.brandRed.withValues(alpha: 0.55),
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: cargando
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      texto,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
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
                      validator: (value) =>
                          (value == null ||
                              !RegExp(r'^\d{8}$').hasMatch(value.trim()))
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
                          (value == null ||
                              !RegExp(
                                r'^[A-Z0-9]{6}$',
                                caseSensitive: false,
                              ).hasMatch(value.trim()))
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
                      onChanged: (v) {
                        AppTheme.tap();
                        setState(() => _soatVigente = v ?? false);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppTheme.confirmGreen,
                      title: const Text('Cuento con SOAT vigente (RN-S01)'),
                    ),
                    const SizedBox(height: 16),
                    _botonPrincipal(
                      texto: 'CREAR CUENTA',
                      cargando: _registrando,
                      onPressed: _registrarUsuario,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
