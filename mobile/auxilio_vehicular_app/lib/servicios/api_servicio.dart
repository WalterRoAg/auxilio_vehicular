import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiServicio {
  final String urlBase = "https://auxilio-vehicular.onrender.com/api";

  // LOGIN MOVIL
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$urlBase/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // REGISTRO
  Future<bool> registrarUsuario(Map<String, dynamic> datos) async {
    try {
      final res = await http.post(
        Uri.parse('$urlBase/registrar'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(datos),
      );

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // VEHICULOS
  Future<List<dynamic>> obtenerVehiculos(String usuarioId) async {
    try {
      final res = await http.get(
        Uri.parse('$urlBase/vehiculos/usuario/$usuarioId'),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> registrarVehiculo(Map<String, dynamic> datos) async {
    try {
      final res = await http.post(
        Uri.parse('$urlBase/vehiculos'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(datos),
      );

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> enviarEmergencia({
    required String clienteId,
    required double latitud,
    required double longitud,
    String? descripcion,
    File? archivoAudio,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$urlBase/incidentes/crear-ia'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "cliente_id": clienteId,
          "lat": latitud,
          "lng": longitud,
          "descripcion": descripcion ?? "Emergencia",
        }),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }

      print("ERROR BACKEND: ${res.statusCode}");
      print(res.body);
      return null;
    } catch (e) {
      print("ERROR ENVIAR EMERGENCIA: $e");
      return null;
    }
  }

  // CONFIRMAR TALLER
  Future<bool> confirmarTaller(String incidenteId, String tallerId) async {
    try {
      final res = await http.post(
        Uri.parse('$urlBase/emergencia/confirmar-taller'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"incidente_id": incidenteId, "taller_id": tallerId}),
      );

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> obtenerNotificaciones(String usuarioId) async {
    try {
      final res = await http.get(
        Uri.parse('$urlBase/notificaciones/$usuarioId'),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> marcarNotificacionLeida(String id) async {
    try {
      await http.put(Uri.parse('$urlBase/notificaciones/leer/$id'));
    } catch (e) {}
  }

  Future<Map<String, dynamic>?> obtenerPerfil(String userId) async {
    final res = await http.get(Uri.parse('$urlBase/perfil/$userId'));

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  Future<bool> actualizarPerfil(
    String userId,
    String nombre,
    String telefono,
  ) async {
    final res = await http.put(
      Uri.parse('$urlBase/perfil/$userId'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": nombre, "phone": telefono}),
    );

    return res.statusCode == 200;
  }

  Future<bool> cancelarIncidente(String incidenteId) async {
    try {
      final res = await http.put(
        Uri.parse('$urlBase/incidentes/cancelar/$incidenteId'),
      );

      return res.statusCode == 200;
    } catch (e) {
      print("ERROR CANCELAR INCIDENTE: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> obtenerTrazabilidad(String incidenteId) async {
    try {
      final res = await http.get(
        Uri.parse('$urlBase/emergencia/trazabilidad/$incidenteId'),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }

      return null;
    } catch (e) {
      print("ERROR TRAZABILIDAD: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> obtenerDetalleIncidente(
    String incidenteId,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$urlBase/incidentes/detalle/$incidenteId'),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }

      return null;
    } catch (e) {
      print("ERROR DETALLE INCIDENTE: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> obtenerSolicitudActiva(String clienteId) async {
    try {
      final res = await http.get(
        Uri.parse('$urlBase/incidentes/activa/cliente/$clienteId'),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }

      return null;
    } catch (e) {
      print("ERROR SOLICITUD ACTIVA: $e");
      return null;
    }
  }

  Future<bool> subirImagenIncidente({
    required String incidenteId,
    required File imagen,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$urlBase/emergencia/subir-imagen'),
      );

      request.fields['incidente_id'] = incidenteId;
      request.fields['es_complementaria'] = 'false';

      request.files.add(
        await http.MultipartFile.fromPath('archivo', imagen.path),
      );

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      return res.statusCode == 200;
    } catch (e) {
      print("ERROR SUBIR IMAGEN: $e");
      return false;
    }
  }

  Future<bool> finalizarIncidente(String incidenteId) async {
    try {
      final res = await http.put(
        Uri.parse('$urlBase/incidentes/finalizar/$incidenteId'),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelarNoLlego(String incidenteId) async {
    try {
      final res = await http.put(
        Uri.parse('$urlBase/incidentes/cancelar-no-llego/$incidenteId'),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
