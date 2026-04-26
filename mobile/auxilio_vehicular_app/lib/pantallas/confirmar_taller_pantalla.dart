import 'package:flutter/material.dart';
import '../servicios/api_servicio.dart';

class ConfirmarTallerPantalla extends StatelessWidget {
  final String incidenteId;
  final List ofertas;
  final ApiServicio _api = ApiServicio();

  ConfirmarTallerPantalla({
    super.key,
    required this.incidenteId,
    required this.ofertas,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seleccionar Taller")),
      body: ofertas.isEmpty
          ? const Center(child: Text("Esperando ofertas de talleres..."))
          : ListView.builder(
              itemCount: ofertas.length,
              itemBuilder: (context, index) {
                final oferta = ofertas[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.build, color: Colors.blue),
                    title: Text(oferta['nombre_taller'] ?? 'Taller'),
                    subtitle: Text(
                      "Costo: Bs. ${oferta['monto']} - Tiempo: ${oferta['tiempo']} min",
                    ),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        bool exito = await _api.confirmarTaller(
                          incidenteId,
                          oferta['taller_id'],
                        );
                        if (exito) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "¡Taller confirmado! El técnico está en camino.",
                              ),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Elegir"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
