import 'dart:async';
import 'package:flutter/material.dart';
import '../servicios/api_servicio.dart';

class NotificacionListener extends StatefulWidget {
  final Widget child;
  final String usuarioId;

  const NotificacionListener({
    super.key,
    required this.child,
    required this.usuarioId,
  });

  @override
  State<NotificacionListener> createState() => _NotificacionListenerState();
}

class _NotificacionListenerState extends State<NotificacionListener> {
  final _api = ApiServicio();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Revisa notificaciones cada 10 segundos (CU16)
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _revisarNotificaciones();
    });
  }

  void _revisarNotificaciones() async {
    final lista = await _api.obtenerNotificaciones(widget.usuarioId);
    if (lista.isNotEmpty) {
      for (var notif in lista) {
        _mostrarAlerta(notif);
        await _api.marcarNotificacionLeida(notif['id']);
      }
    }
  }

  void _mostrarAlerta(dynamic notif) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notif['titulo'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(notif['mensaje']),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
