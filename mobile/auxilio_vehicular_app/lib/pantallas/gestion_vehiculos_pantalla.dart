import 'package:flutter/material.dart';
import '../servicios/api_servicio.dart';

class GestionVehiculosPantalla extends StatefulWidget {
  final String usuarioId;
  const GestionVehiculosPantalla({super.key, required this.usuarioId});

  @override
  State<GestionVehiculosPantalla> createState() =>
      _GestionVehiculosPantallaState();
}

class _GestionVehiculosPantallaState extends State<GestionVehiculosPantalla> {
  final _api = ApiServicio();
  List _vehiculos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarVehiculos();
  }

  void _cargarVehiculos() async {
    final lista = await _api.obtenerVehiculos(widget.usuarioId);
    setState(() {
      _vehiculos = lista;
      _cargando = false;
    });
  }

  void _mostrarDialogoRegistro() {
    final placaController = TextEditingController();
    final modeloController = TextEditingController();
    final marcaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Registrar Vehículo (CU5)"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: marcaController,
              decoration: const InputDecoration(
                labelText: "Marca (ej. Toyota)",
              ),
            ),
            TextField(
              controller: modeloController,
              decoration: const InputDecoration(
                labelText: "Modelo (ej. Hilux)",
              ),
            ),
            TextField(
              controller: placaController,
              decoration: const InputDecoration(labelText: "Placa"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final datos = {
                "user_id": widget.usuarioId,
                "plate": placaController.text,
                "brand": marcaController.text,
                "model": modeloController.text,
              };
              bool ok = await _api.registrarVehiculo(datos);
              if (ok) {
                Navigator.pop(context);
                _cargarVehiculos();
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Vehículos")),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _vehiculos.isEmpty
          ? const Center(child: Text("No tienes vehículos registrados."))
          : ListView.builder(
              itemCount: _vehiculos.length,
              itemBuilder: (context, index) {
                final v = _vehiculos[index];
                return ListTile(
                  leading: const Icon(Icons.directions_car, color: Colors.red),
                  title: Text("${v['brand']} ${v['model']}"),
                  subtitle: Text("Placa: ${v['plate']}"),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoRegistro,
        child: const Icon(Icons.add),
      ),
    );
  }
}
