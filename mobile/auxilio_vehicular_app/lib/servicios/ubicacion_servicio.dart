import 'package:geolocator/geolocator.dart';

class UbicacionServicio {
  // CU8: Obtener la posición actual del GPS
  Future<Position> determinarPosicion() async {
    bool servicioHabilitado;
    LocationPermission permiso;

    // Verificar si el GPS está encendido
    servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      return Future.error('El servicio de ubicación está desactivado.');
    }

    permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        return Future.error('Los permisos de ubicación fueron denegados.');
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      return Future.error('Los permisos están denegados permanentemente.');
    }

    // CU8: Retornar coordenadas actuales
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
