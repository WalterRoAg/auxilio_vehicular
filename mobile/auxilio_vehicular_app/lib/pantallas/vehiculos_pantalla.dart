import 'package:flutter/material.dart';
import '../servicios/api_servicio.dart';

class VehiculosPantalla extends StatefulWidget {
  final String userId;

  const VehiculosPantalla({super.key, required this.userId});

  @override
  State<VehiculosPantalla> createState() => _VehiculosPantallaState();
}

class _VehiculosPantallaState extends State<VehiculosPantalla> {
  final _api = ApiServicio();

  List lista = [];
  bool cargando = true;

  final placa = TextEditingController();
  final marca = TextEditingController();
  final modelo = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    lista = await _api.obtenerVehiculos(widget.userId);
    setState(() => cargando = false);
  }

  Future<void> agregar() async {
    bool ok = await _api.registrarVehiculo({
      "user_id": widget.userId,
      "plate": placa.text,
      "brand": marca.text,
      "model": modelo.text,
    });

    if (ok) {
      placa.clear();
      marca.clear();
      modelo.clear();
      cargar();
      Navigator.pop(context);
    }
  }

  void modalAgregar() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nuevo Vehículo"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: placa,
                decoration: const InputDecoration(labelText: "Placa"),
              ),
              TextField(
                controller: marca,
                decoration: const InputDecoration(labelText: "Marca"),
              ),
              TextField(
                controller: modelo,
                decoration: const InputDecoration(labelText: "Modelo"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(onPressed: agregar, child: const Text("Guardar")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          const SizedBox(height: 10),
          const Text(
            "Mis Vehículos",
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          ...lista.map(
            (v) => Card(
              child: ListTile(
                leading: const Icon(Icons.directions_car, color: Colors.red),
                title: Text(v["plate"]),
                subtitle: Text("${v["brand"]} - ${v["model"]}"),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: modalAgregar,
        child: const Icon(Icons.add),
      ),
    );
  }
}
