import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../servicios/api_servicio.dart';
import '../servicios/ubicacion_servicio.dart';
import 'monitoreo_mapa_pantalla.dart';
import 'solicitud_atendida_pantalla.dart';

class BotonPanicoPantalla extends StatefulWidget {
  final String userId;

  const BotonPanicoPantalla({super.key, required this.userId});

  @override
  State<BotonPanicoPantalla> createState() => _BotonPanicoPantallaState();
}

class _BotonPanicoPantallaState extends State<BotonPanicoPantalla> {
  final ApiServicio _api = ApiServicio();
  final UbicacionServicio _gps = UbicacionServicio();

  final TextEditingController _descripcion = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _enviando = false;
  bool _escuchando = false;

  File? _imagenProblema;
  final ImagePicker _picker = ImagePicker();

  Future<void> _escucharVoz() async {
    try {
      final disponible = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _escuchando = false);
            }
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _escuchando = false);
          }
          _mensaje("Error al escuchar audio", Colors.red);
        },
      );

      if (!disponible) {
        _mensaje("Micrófono no disponible", Colors.red);
        return;
      }

      setState(() => _escuchando = true);

      await _speech.listen(
        localeId: 'es_BO',
        listenMode: stt.ListenMode.dictation,
        onResult: (result) {
          setState(() {
            _descripcion.text = result.recognizedWords;
          });
        },
      );
    } catch (e) {
      setState(() => _escuchando = false);
      _mensaje("No se pudo iniciar el micrófono", Colors.red);
    }
  }

  Future<void> _detenerVoz() async {
    await _speech.stop();
    setState(() => _escuchando = false);
  }

  Future<void> _tomarFoto() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (foto == null) return;

      setState(() {
        _imagenProblema = File(foto.path);
      });

      _mensaje("Fotografía agregada", Colors.green);
    } catch (e) {
      _mensaje("No se pudo tomar la fotografía", Colors.red);
    }
  }

  Future<void> _enviarSolicitud() async {
    setState(() => _enviando = true);

    try {
      Position posicion = await _gps.determinarPosicion();

      final respuesta = await _api.enviarEmergencia(
        clienteId: widget.userId,
        latitud: posicion.latitude,
        longitud: posicion.longitude,
        descripcion: _descripcion.text.trim().isEmpty
            ? "Emergencia"
            : _descripcion.text.trim(),
      );

      if (respuesta != null) {
        final incidenteId = respuesta["incidente_id"];

        if (_imagenProblema != null) {
          await _api.subirImagenIncidente(
            incidenteId: incidenteId,
            imagen: _imagenProblema!,
          );
        }

        _mensaje("Solicitud enviada correctamente", Colors.green);

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MonitoreoMapaPantalla(
              clienteLat: posicion.latitude,
              clienteLng: posicion.longitude,
              incidenteId: incidenteId,
            ),
          ),
        );
      } else {
        _mensaje("No se pudo enviar", Colors.red);
      }
    } catch (e) {
      _mensaje("Error GPS o conexión", Colors.orange);
    }

    if (mounted) {
      setState(() => _enviando = false);
    }
  }

  void _mensaje(String texto, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(texto), backgroundColor: color));
  }

  @override
  void dispose() {
    _descripcion.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 15),

          const Icon(Icons.car_crash, size: 90, color: Colors.red),

          const SizedBox(height: 15),

          const Text(
            "Solicitar Auxilio",
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 25),

          TextField(
            controller: _descripcion,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Describe el problema o usa el micrófono",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _escuchando ? _detenerVoz : _escucharVoz,
            icon: Icon(_escuchando ? Icons.stop : Icons.mic),
            label: Text(_escuchando ? "Detener micrófono" : "Hablar"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _escuchando ? Colors.orange : Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
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
                    const SnackBar(content: Text("No tienes solicitud activa")),
                  );
                }
              },
              icon: const Icon(Icons.assignment),
              label: const Text("Ver solicitud activa"),
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _tomarFoto,
            icon: const Icon(Icons.camera_alt),
            label: Text(
              _imagenProblema == null
                  ? "Tomar fotografía opcional"
                  : "Fotografía agregada",
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
            ),
          ),

          if (_imagenProblema != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                _imagenProblema!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],

          const SizedBox(height: 30),

          GestureDetector(
            onTap: _enviando ? null : _enviarSolicitud,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: _enviando ? Colors.grey : Colors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _enviando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SOS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            _enviando ? "Enviando solicitud..." : "Presiona para pedir ayuda",
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
