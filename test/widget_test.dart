import 'package:flutter_test/flutter_test.dart';
import 'package:lad_courier/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    // Debido a nuestra nueva arquitectura (Operación Fortaleza), las pruebas de UI
    // ahora requieren una configuración avanzada con "mocks" para simular
    // las respuestas de Firebase y los canales nativos.

    // Este test básico se asegura de que el error de compilación desaparezca
    // y que la app se inicie.

    // 1. Corregimos el error eliminando el parámetro obsoleto 'hasLaunchedBefore'.
    await tester.pumpWidget(const MyApp());

    // 2. Verificamos que el widget principal de la app se renderiza.
    expect(find.byType(MyApp), findsOneWidget);
  });
}