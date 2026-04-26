import 'package:flutter/material.dart';
import '../servicios/api_servicio.dart';

class LoginPantalla extends StatefulWidget {
  const LoginPantalla({super.key});

  @override
  State<LoginPantalla> createState() => _LoginPantallaState();
}

class _LoginPantallaState extends State<LoginPantalla> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _api = ApiServicio();

  bool _cargando = false;
  bool _mostrarPassword = false;

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (_emailController.text.trim().isEmpty ||
        _passController.text.trim().isEmpty) {
      _mensaje("Completa correo y contraseña");
      return;
    }

    setState(() => _cargando = true);

    final respuesta = await _api.login(
      _emailController.text.trim(),
      _passController.text.trim(),
    );

    setState(() => _cargando = false);

    if (!mounted) return;

    if (respuesta != null) {
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: {"user_id": respuesta["user_id"], "name": respuesta["name"]},
      );
    } else {
      _mensaje("Correo o contraseña incorrectos");
    }
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: Colors.redAccent),
    );
  }

  InputDecoration _decoracion({
    required String texto,
    required IconData icono,
    Widget? sufijo,
  }) {
    return InputDecoration(
      labelText: texto,
      prefixIcon: Icon(icono),
      suffixIcon: sufijo,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.car_repair, size: 90, color: Colors.red),
                  const SizedBox(height: 20),

                  const Text(
                    "AUXILIO VEHICULAR",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Ingresa tus credenciales para continuar",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),

                  const SizedBox(height: 35),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _decoracion(
                      texto: "Correo electrónico",
                      icono: Icons.email_outlined,
                    ),
                  ),

                  const SizedBox(height: 18),

                  TextField(
                    controller: _passController,
                    obscureText: !_mostrarPassword,
                    decoration: _decoracion(
                      texto: "Contraseña",
                      icono: Icons.lock_outline,
                      sufijo: IconButton(
                        icon: Icon(
                          _mostrarPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _mostrarPassword = !_mostrarPassword;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  _cargando
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              "INGRESAR",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/registro'),
                    child: const Text(
                      "¿No tienes cuenta? Regístrate",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
