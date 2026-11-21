import 'package:flutter_test/flutter_test.dart';
import 'package:leon_de_juda_app/main.dart';

void main() {
  testWidgets('Carga inicial de la app León de Judá', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.textContaining('León de Judá'), findsWidgets);
  });
}