import 'package:flutter/material.dart';
import '../servicios/api_servicio.dart';

class RegistroPantalla extends StatefulWidget {
  const RegistroPantalla({super.key});

  @override
  State<RegistroPantalla> createState() => _RegistroPantallaState();
}

class _RegistroPantallaState extends State<RegistroPantalla> {
  final _api = ApiServicio();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _estaCargando = false;

  void _ejecutarRegistro() async {
    if (_nombreController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    setState(() => _estaCargando = true);

    // CU1: El rol siempre es 'cliente' desde la App Móvil
    final datos = {
      "full_name": _nombreController.text,
      "email": _emailController.text,
      "password": _passController.text,
      "role": "cliente",
      "phone": "70000000",
    };

    bool exito = await _api.registrarUsuario(datos);

    setState(() => _estaCargando = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("¡Cuenta creada! Ya puedes entrar")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al registrar. Revisa tu conexión."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Cuenta de Cliente")),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Icon(Icons.person_add, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: "Nombre Completo"),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Correo"),
            ),
            TextField(
              controller: _passController,
              decoration: const InputDecoration(labelText: "Contraseña"),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            _estaCargando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _ejecutarRegistro,
                    child: const Text("REGISTRARME"),
                  ),
          ],
        ),
      ),
    );
  }
}
