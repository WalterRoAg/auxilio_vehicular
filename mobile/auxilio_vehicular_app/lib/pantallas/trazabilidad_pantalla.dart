import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Asegúrate que esta línea no tenga error tras el pub get
import 'package:latlong2/latlong.dart';

class TrazabilidadPantalla extends StatelessWidget {
  final double lat;
  final double lng;

  const TrazabilidadPantalla({super.key, required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Técnico en camino")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(lat, lng), // Antes era center
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.tuapp.auxilio',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(lat, lng),
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
