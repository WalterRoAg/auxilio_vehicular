import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../servicios/api_servicio.dart';

class SolicitudAtendidaPantalla extends StatefulWidget {
  final String incidenteId;

  const SolicitudAtendidaPantalla({super.key, required this.incidenteId});

  @override
  State<SolicitudAtendidaPantalla> createState() =>
      _SolicitudAtendidaPantallaState();
}

class _SolicitudAtendidaPantallaState extends State<SolicitudAtendidaPantalla> {
  final MapController _mapController = MapController();

  Timer? _timer;
  bool loading = true;

  double clienteLat = 0;
  double clienteLng = 0;
  double tallerLat = 0;
  double tallerLng = 0;

  String status = '';
  String nombreTaller = '';
  String especialidad = '';
  String direccion = '';
  double precio = 0;
  int tiempo = 0;
  double rating = 0;

  DateTime? horaAceptacion;
  bool puedeAccionar = false;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();

    _timer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _cargarDetalle(),
    );
  }

  Future<void> _cargarDetalle() async {
    final data = await ApiServicio().obtenerDetalleIncidente(
      widget.incidenteId,
    );

    if (!mounted || data == null) return;

    final taller = data["taller"];
    final oferta = data["oferta"];

    setState(() {
      clienteLat = double.tryParse(data["lat"].toString()) ?? 0;
      clienteLng = double.tryParse(data["lng"].toString()) ?? 0;
      status = data["status"] ?? '';

      if (taller != null) {
        nombreTaller = taller["nombre_taller"] ?? "Taller";
        especialidad = taller["especialidad"] ?? "Mecánica general";
        direccion = taller["direccion"] ?? "Sin dirección";
        tallerLat = double.tryParse(taller["latitud"].toString()) ?? clienteLat;
        tallerLng =
            double.tryParse(taller["longitud"].toString()) ?? clienteLng;
        rating = double.tryParse(taller["rating"].toString()) ?? 5;
      }

      if (oferta != null) {
        precio = double.tryParse(oferta["precio_estimado"].toString()) ?? 0;
        tiempo = int.tryParse(oferta["tiempo_llegada_minutos"].toString()) ?? 0;
      }

      if (data["fecha_aceptacion"] != null) {
        horaAceptacion ??= DateTime.now();
      }

      if (horaAceptacion != null && tiempo > 0) {
        puedeAccionar = DateTime.now().isAfter(
          horaAceptacion!.add(Duration(minutes: tiempo)),
        );
      }

      loading = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final cliente = LatLng(clienteLat, clienteLng);
    final taller = LatLng(tallerLat, tallerLng);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Solicitud atendida"),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: cliente, initialZoom: 15),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.auxilio_vehicular_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: cliente,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 48,
                      ),
                    ),
                    Marker(
                      point: taller,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.car_repair,
                        color: Colors.blue,
                        size: 45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tu solicitud fue aceptada",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    nombreTaller,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),

                  Text(especialidad),
                  Text(direccion),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoBox("Precio", "Bs. ${precio.toStringAsFixed(2)}"),
                      _infoBox("Llegada", "$tiempo min"),
                      _infoBox("Rating", "⭐ $rating"),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.directions_car, color: Colors.green),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "El técnico está en camino a tu ubicación.",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  if (!puedeAccionar)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "Podrás finalizar o cancelar cuando pasen los $tiempo minutos estimados.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                  if (puedeAccionar) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final ok = await ApiServicio().finalizarIncidente(
                            widget.incidenteId,
                          );

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? "Servicio finalizado"
                                    : "No se pudo finalizar",
                              ),
                              backgroundColor: ok ? Colors.green : Colors.red,
                            ),
                          );

                          if (ok) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text("Finalizar servicio"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final ok = await ApiServicio().cancelarNoLlego(
                            widget.incidenteId,
                          );

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? "Solicitud cancelada"
                                    : "No se pudo cancelar",
                              ),
                              backgroundColor: ok ? Colors.orange : Colors.red,
                            ),
                          );

                          if (ok) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.cancel),
                        label: const Text("Cancelar porque no llegó"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Volver"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String titulo, String valor) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(titulo, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 5),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
