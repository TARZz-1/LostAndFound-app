import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  bool _cargando = false;
  String? _mensajeError;

  Future<void> _iniciarSesionConGoogle() async {
    setState(() {
      _cargando = true;
      _mensajeError = null;
    });

    try {
      await _authService.signInWithGoogle();
    } catch (ex) {
      debugPrint('Error en signInWithGoogle: $ex');
      if (!mounted) return;
      setState(() {
        _mensajeError =
            'ERROR al iniciar sesion con Google. Intente nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 48,
                backgroundColor: colores.primaryContainer,
                child: Icon(
                  Icons.travel_explore_rounded,
                  size: 52,
                  color: colores.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Objetos Perdidos USM',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colores.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Publica y encuentra articulos extraviados dentro de la sede Viña del Mar',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: colores.onSurfaceVariant),
              ),
              const Spacer(),
              if (_mensajeError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colores.errorContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: colores.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _mensajeError!,
                          style: TextStyle(color: colores.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
              ],
              _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton.icon(
                      onPressed: _iniciarSesionConGoogle,
                      icon: const Icon(Icons.account_circle_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Iniciar sesion con Google',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
