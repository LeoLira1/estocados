import 'package:estocados_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app shell renders', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const EstocadosApp());
    expect(find.text('Estocados'), findsAtLeastNWidgets(1));
  });
}
