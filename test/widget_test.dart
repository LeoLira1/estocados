import 'package:estocados_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app shell renders', (tester) async {
    await tester.pumpWidget(const EstocadosApp());
    expect(find.text('Estoque de Cooperados'), findsOneWidget);
  });
}
