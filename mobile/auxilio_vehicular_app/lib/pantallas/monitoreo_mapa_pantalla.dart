import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../servicios/api_servicio.dart';

class MonitoreoMapaPantalla extends StatefulWidget {
  final double clienteLat;
  final double clienteLng;
  final String incidenteId;

  const MonitoreoMapaPantalla({
    super.key,
    required this.clienteLat,
    required this.clienteLng,
    required this.incidenteId,
  });

  @override
  State<MonitoreoMapaPantalla> createState() => _MonitoreoMapaPantallaState();
}

class _MonitoreoMapaPantallaState extends State<MonitoreoMapaPantalla> {
  final MapController _mapController = MapController();

  late LatLng clienteUbicacion;
  LatLng? tecnicoUbicacion;

  Timer? _timerTrazabilidad;
  StreamSubscription<Position>? _gpsSub;

  String status = "pendiente";

  String nombreTaller = "";
  String direccionTaller = "";
  double precio = 0;
  int tiempoLlegada = 0;
  bool aceptada = false;

  @override
  void initState() {
    super.initState();

    clienteUbicacion = LatLng(widget.clienteLat, widget.clienteLng);

    tecnicoUbicacion = LatLng(
      widget.clienteLat + 0.001,
      widget.clienteLng + 0.001,
    );

    _escucharGpsCliente();
    _consultarTrazabilidad();
    _consultarDetalleIncidente();

    _timerTrazabilidad = Timer.periodic(const Duration(seconds: 4), (_) {
      _consultarTrazabilidad();
      _consultarDetalleIncidente();
    });
  }

  void _escucharGpsCliente() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _gpsSub = Geolocator.getPositionStream(locationSettings: settings).listen((
      Position position,
    ) {
      if (!mounted) return;

      setState(() {
        clienteUbicacion = LatLng(position.latitude, position.longitude);
      });

      _mapController.move(clienteUbicacion, 16);
    });
  }

  Future<void> _consultarTrazabilidad() async {
    final data = await ApiServicio().obtenerTrazabilidad(widget.incidenteId);

    if (!mounted || data == null) return;
    if (data["error"] != null) return;

    final lat = data["lat"];
    final lng = data["lng"];

    setState(() {
      status = data["status"] ?? status;

      if (lat != null && lng != null) {
        tecnicoUbicacion = LatLng(
          double.tryParse(lat.toString()) ?? clienteUbicacion.latitude,
          double.tryParse(lng.toString()) ?? clienteUbicacion.longitude,
        );
      }
    });
  }

  void _centrarEnCliente() {
    _mapController.move(clienteUbicacion, 16);
  }

  void _centrarEnTecnico() {
    if (tecnicoUbicacion != null) {
      _mapController.move(tecnicoUbicacion!, 16);
    }
  }

  Future<void> _cancelarSolicitud() async {
    final ok = await ApiServicio().cancelarIncidente(widget.incidenteId);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Solicitud cancelada correctamente"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo cancelar la solicitud"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timerTrazabilidad?.cancel();
    _gpsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      Marker(
        point: clienteUbicacion,
        width: 60,
        height: 60,
        child: const Icon(Icons.location_pin, color: Colors.red, size: 48),
      ),
      Marker(
        point: clienteUbicacion,
        width: 45,
        height: 45,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.20),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: const Icon(Icons.my_location, color: Colors.blue, size: 26),
        ),
      ),
    ];

    if (tecnicoUbicacion != null) {
      markers.add(
        Marker(
          point: tecnicoUbicacion!,
          width: 55,
          height: 55,
          child: const Icon(
            Icons.directions_car,
            color: Colors.indigo,
            size: 42,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trazabilidad en tiempo real"),
        backgroundColor: Colors.redAccent,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: clienteUbicacion,
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.auxilio_vehicular_app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),

          Positioned(
            right: 16,
            top: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "gps_cliente",
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  onPressed: _centrarEnCliente,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "gps_tecnico",
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo,
                  onPressed: _centrarEnTecnico,
                  child: const Icon(Icons.directions_car),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const CircularProgressIndicator(strokeWidth: 3),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    aceptada
                        ? "$nombreTaller aceptó tu solicitud. Llegará en $tiempoLlegada min. Precio: Bs. $precio"
                        : "Esperando asignación del taller...",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _cancelarSolicitud,
              icon: const Icon(Icons.cancel),
              label: const Text("Cancelar solicitud"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _consultarDetalleIncidente() async {
    final data = await ApiServicio().obtenerDetalleIncidente(
      widget.incidenteId,
    );

    if (!mounted || data == null) return;

    final taller = data["taller"];
    final oferta = data["oferta"];

    setState(() {
      status = data["status"] ?? status;

      if (taller != null && oferta != null) {
        aceptada = true;
        nombreTaller = taller["nombre_taller"] ?? "Taller";
        direccionTaller = taller["direccion"] ?? "Sin dirección";
        precio = double.tryParse(oferta["precio_estimado"].toString()) ?? 0;
        tiempoLlegada =
            int.tryParse(oferta["tiempo_llegada_minutos"].toString()) ?? 0;

        tecnicoUbicacion = LatLng(
          double.tryParse(taller["latitud"].toString()) ??
              clienteUbicacion.latitude,
          double.tryParse(taller["longitud"].toString()) ??
              clienteUbicacion.longitude,
        );
      }
    });
  }
}
