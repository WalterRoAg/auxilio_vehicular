import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificacionServicio {
  final String urlBase = "http://TU_IP_LOCAL:8000/api";

  // Registra el dispositivo en el backend para recibir push
  Future<void> registrarTokenDispositivo(String usuarioId, String token) async {
    await http.put(
      Uri.parse('$urlBase/usuarios/token-notificacion'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"usuario_id": usuarioId, "token": token}),
    );
  }
}
