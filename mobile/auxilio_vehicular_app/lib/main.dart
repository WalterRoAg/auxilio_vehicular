import 'package:flutter/material.dart';
import 'pantallas/registro_pantalla.dart';
import 'pantallas/boton_panico_pantalla.dart';
import 'pantallas/login_pantalla.dart';
import 'widgets/notificacion_listener.dart';
import 'pantallas/perfil_pantalla.dart';
import 'pantallas/vehiculos_pantalla.dart';
import 'pantallas/boton_panico_pantalla.dart';
import 'pantallas/solicitud_atendida_pantalla.dart';
import 'servicios/api_servicio.dart';

void main() {
  runApp(const MiAplicacionAuxilio());
}

class MiAplicacionAuxilio extends StatelessWidget {
  const MiAplicacionAuxilio({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auxilio Vehicular',
      theme: ThemeData(primarySwatch: Colors.red),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPantalla(),
        '/registro': (context) => const RegistroPantalla(),

        '/home': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;

          return PantallaPrincipal(
            userId: args["user_id"],
            nombre: args["name"],
          );
        },
      },
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  final String userId;
  final String nombre;

  const PantallaPrincipal({
    super.key,
    required this.userId,
    required this.nombre,
  });

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final paginas = [
      BotonPanicoPantalla(userId: widget.userId),
      VehiculosPantalla(userId: widget.userId),
      PerfilPantalla(userId: widget.userId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Auxilio Vehicular"),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () async {
              final data = await ApiServicio().obtenerSolicitudActiva(
                widget.userId,
              );

              if (!context.mounted) return;

              if (data != null && data["activa"] == true) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SolicitudAtendidaPantalla(
                      incidenteId: data["incidente_id"],
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("No tienes solicitudes activas"),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: paginas[index],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        selectedItemColor: Colors.red,
        onTap: (i) {
          setState(() => index = i);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: "Vehículos",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}
