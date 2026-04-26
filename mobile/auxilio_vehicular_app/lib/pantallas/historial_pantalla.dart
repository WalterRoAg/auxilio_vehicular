import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HistorialPantalla extends StatelessWidget {
  final String usuarioId;
  const HistorialPantalla({super.key, required this.usuarioId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mi Historial de Servicios")),
      body: FutureBuilder<http.Response>(
        future: http.get(
          Uri.parse("http://TU_IP_LOCAL:8000/api/historial/$usuarioId"),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Error al cargar historial"));
          }

          final List historial = jsonDecode(
            snapshot.data!.body,
          ); // Corregido con '!'

          return ListView.builder(
            itemCount: historial.length,
            itemBuilder: (context, index) {
              final item = historial[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: const Text("Servicio finalizado"),
                subtitle: Text("Fecha: ${item['fecha_finalizacion']}"),
                trailing: Text(
                  "Bs. ${item['monto_final']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
