import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auxilio_vehicular_app/main.dart'; // Asegúrate que este nombre coincida con tu proyecto

void main() {
  testWidgets('Prueba de humo de inicio', (WidgetTester tester) async {
    // Cambiamos MyApp por MiAplicacionAuxilio
    await tester.pumpWidget(const MiAplicacionAuxilio());

    // Verificamos que aparezca el texto del CU1
    expect(find.text('Registrarse (CU1)'), findsOneWidget);
    expect(find.text('No existe este texto'), findsNothing);
  });
}
