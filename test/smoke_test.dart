import 'package:estocados_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('render app shell', (tester) async {
    await tester.pumpWidget(const EstocadosApp());
    expect(find.text('Estocados'), findsOneWidget);
  });
}
