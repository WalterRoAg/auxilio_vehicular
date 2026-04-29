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
      status = data["status"]?.toString() ?? '';

      if (taller != null) {
        nombreTaller = taller["nombre_taller"]?.toString() ?? "Taller";
        especialidad = taller["especialidad"]?.toString() ?? "Mecánica general";
        direccion = taller["direccion"]?.toString() ?? "Sin dirección";

        tallerLat = double.tryParse(taller["latitud"].toString()) ?? clienteLat;
        tallerLng =
            double.tryParse(taller["longitud"].toString()) ?? clienteLng;

        rating = double.tryParse(taller["rating"].toString()) ?? 0;
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
        foregroundColor: Colors.white,
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: cliente, initialZoom: 13),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.auxilio_vehicular_app',
                ),

                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [taller, cliente],
                      strokeWidth: 5,
                      color: Colors.red,
                    ),
                  ],
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

          DraggableScrollableSheet(
            initialChildSize: 0.47,
            minChildSize: 0.35,
            maxChildSize: 0.75,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 45,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        "Tu solicitud fue aceptada",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        nombreTaller,
                        style: const TextStyle(
                          fontSize: 21,
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
                          _infoBox(
                            "Precio",
                            "Bs. ${precio.toStringAsFixed(2)}",
                          ),
                          _infoBox("Llegada", "$tiempo min"),
                          _infoBox("Rating", "⭐ ${rating.toStringAsFixed(1)}"),
                        ],
                      ),

                      const SizedBox(height: 16),

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

                      const SizedBox(height: 12),

                      if (!puedeAccionar)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
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

                      const SizedBox(height: 14),

                      if (puedeAccionar) ...[
                        _botonAccion(
                          texto: "Finalizar servicio",
                          icono: Icons.check_circle,
                          color: Colors.green,
                          onPressed: _finalizarServicio,
                        ),

                        const SizedBox(height: 10),

                        _botonAccion(
                          texto: "Cancelar porque no llegó",
                          icono: Icons.cancel,
                          color: Colors.red,
                          onPressed: _cancelarNoLlego,
                        ),

                        const SizedBox(height: 10),
                      ],

                      _botonAccion(
                        texto: "Volver",
                        icono: Icons.arrow_back,
                        color: Colors.red,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _finalizarServicio() async {
    final ok = await ApiServicio().finalizarIncidente(widget.incidenteId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? "Servicio finalizado" : "No se pudo finalizar"),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );

    if (ok) Navigator.pop(context);
  }

  Future<void> _cancelarNoLlego() async {
    final ok = await ApiServicio().cancelarNoLlego(widget.incidenteId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? "Solicitud cancelada" : "No se pudo cancelar"),
        backgroundColor: ok ? Colors.orange : Colors.red,
      ),
    );

    if (ok) Navigator.pop(context);
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
          Text(
            valor,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _botonAccion({
    required String texto,
    required IconData icono,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icono),
        label: Text(texto),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
