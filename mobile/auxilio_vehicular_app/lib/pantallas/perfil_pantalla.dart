import 'package:flutter/material.dart';
import '../servicios/api_servicio.dart';

class PerfilPantalla extends StatefulWidget {
  final String userId;

  const PerfilPantalla({super.key, required this.userId});

  @override
  State<PerfilPantalla> createState() => _PerfilPantallaState();
}

class _PerfilPantallaState extends State<PerfilPantalla> {
  final _api = ApiServicio();

  final _nombre = TextEditingController();
  final _telefono = TextEditingController();

  String email = "";
  bool cargando = true;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    cargarPerfil();
  }

  Future<void> cargarPerfil() async {
    final data = await _api.obtenerPerfil(widget.userId);

    if (data != null) {
      _nombre.text = data["name"] ?? "";
      _telefono.text = data["phone"] ?? "";
      email = data["email"] ?? "";
    }

    setState(() => cargando = false);
  }

  Future<void> guardar() async {
    setState(() => guardando = true);

    bool ok = await _api.actualizarPerfil(
      widget.userId,
      _nombre.text.trim(),
      _telefono.text.trim(),
    );

    setState(() => guardando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? "Perfil actualizado" : "No se pudo guardar"),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  InputDecoration deco(String txt, IconData icono) {
    return InputDecoration(
      labelText: txt,
      prefixIcon: Icon(icono),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const SizedBox(height: 10),

          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.red.shade100,
            child: const Icon(Icons.person, size: 55, color: Colors.red),
          ),

          const SizedBox(height: 15),

          const Text(
            "Mi Perfil",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 30),

          TextField(
            controller: _nombre,
            decoration: deco("Nombre completo", Icons.person_outline),
          ),

          const SizedBox(height: 18),

          TextField(
            enabled: false,
            decoration: deco(
              "Correo",
              Icons.email_outlined,
            ).copyWith(hintText: email),
          ),

          const SizedBox(height: 18),

          TextField(
            controller: _telefono,
            keyboardType: TextInputType.phone,
            decoration: deco("Teléfono", Icons.phone_outlined),
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: guardando ? null : guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: guardando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "GUARDAR CAMBIOS",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 14),

          TextButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              "Cerrar sesión",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
