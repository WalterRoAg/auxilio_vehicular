import 'dart:async';
import 'package:flutter/material.dart';
import '../servicios/api_servicio.dart';

class SeguimientoPantalla extends StatefulWidget {
  final String incidenteId;

  const SeguimientoPantalla({super.key, required this.incidenteId});

  @override
  State<SeguimientoPantalla> createState() => _SeguimientoPantallaState();
}

class _SeguimientoPantallaState extends State<SeguimientoPantalla> {
  final ApiServicio api = ApiServicio();

  Timer? timer;

  String estado = "Cargando...";
  double? lat;
  double? lng;

  @override
  void initState() {
    super.initState();
    iniciarTracking();
  }

  /// 🔁 INICIA EL TRACKING
  void iniciarTracking() {
    // Primera carga inmediata
    cargarTrazabilidad();

    // Actualización cada 5 segundos
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      cargarTrazabilidad();
    });
  }

  /// 🌐 CONSULTA AL BACKEND
  Future<void> cargarTrazabilidad() async {
    try {
      final data = await api.obtenerTrazabilidad(widget.incidenteId);

      if (!mounted || data == null) return;

      setState(() {
        estado = data["status"]?.toString() ?? "Sin estado";

        lat = data["lat"] != null
            ? double.tryParse(data["lat"].toString())
            : null;

        lng = data["lng"] != null
            ? double.tryParse(data["lng"].toString())
            : null;
      });
    } catch (e) {
      debugPrint("Error tracking: $e");
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seguimiento del servicio")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔹 ESTADO
            Card(
              child: ListTile(
                title: const Text("Estado del servicio"),
                subtitle: Text(estado),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 UBICACIÓN
            if (lat != null && lng != null)
              Card(
                child: ListTile(
                  title: const Text("Ubicación del técnico"),
                  subtitle: Text("Lat: $lat, Lng: $lng"),
                ),
              ),

            const SizedBox(height: 20),

            /// 🔹 TIEMPO ESTIMADO
            Card(
              child: ListTile(
                title: const Text("Tiempo estimado"),
                subtitle: Text(calcularTiempo()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ⏱️ LÓGICA SIMPLE DE TIEMPO
  String calcularTiempo() {
    if (estado == "en_camino") {
      return "10 - 15 minutos";
    } else if (estado == "pendiente") {
      return "Esperando asignación...";
    } else if (estado == "finalizado") {
      return "Servicio completado";
    } else {
      return "Calculando...";
    }
  }
}
