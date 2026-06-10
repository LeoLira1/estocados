import 'dart:convert';

import 'package:estocados_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _tursoResponse() {
  List<Map<String, String>> row(List<String> values) => [
        for (final v in values) {'type': 'text', 'value': v}
      ];

  final body = {
    'results': [
      {
        'type': 'ok',
        'response': {
          'type': 'execute',
          'result': {
            'cols': [
              {'name': 'razao_social'},
              {'name': 'descricao'},
              {'name': 'codigo'},
              {'name': 'armazem'},
              {'name': 'documento'},
              {'name': 'emissao'},
              {'name': 'quantidade'},
              {'name': 'entregue'},
              {'name': 'saldo'},
              {'name': 'tipo'},
            ],
            'rows': [
              row([
                'ANDRE VILELA GOUVEIA',
                'HERBICIDA PROVENCE TOTAL 10L',
                '237078',
                '70',
                '000000574',
                '2026-04-08',
                '29',
                '6',
                '23',
                'S',
              ]),
              row([
                'BRAVO ARMAZENS GERAIS LTDA',
                'HERBICIDA BORAL 500 SC 20L',
                'US254185',
                '01',
                '000080022',
                '2026-04-01',
                '22',
                '0',
                '22',
                'E',
              ]),
              row([
                'BRAVO ARMAZENS GERAIS LTDA',
                'HERBICIDA BORAL FULL 20L',
                'US274189',
                '01',
                '000080026',
                '2026-04-01',
                '375',
                '0',
                '375',
                'E',
              ]),
            ],
          },
        },
      }
    ],
  };
  return http.Response(jsonEncode(body), 200,
      headers: {'content-type': 'application/json'});
}

void main() {
  testWidgets('lista materiais agrupados por cooperado com filtros',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'db_url': 'libsql://fake.turso.io',
      'db_token': 'token',
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(const EstocadosApp());
      await tester.pumpAndSettle();

      // Grupos por cooperado com totais.
      expect(find.textContaining('ANDRE VILELA GOUVEIA'), findsOneWidget);
      expect(find.textContaining('BRAVO ARMAZENS GERAIS LTDA'), findsOneWidget);
      expect(find.textContaining('2 item(s)'), findsOneWidget);

      // Itens com saldo e badge de tipo normalizado (E -> Entrada, S -> Saída).
      expect(find.text('HERBICIDA PROVENCE TOTAL 10L'), findsOneWidget);
      expect(find.text('Saída'), findsOneWidget);
      expect(find.text('Entrada'), findsNWidgets(2));

      // Filtros e resumo.
      expect(find.text('Armazém'), findsOneWidget);
      expect(find.textContaining('3 linha(s)'), findsOneWidget);

      // Filtrar por cooperado reduz as linhas.
      await tester.tap(find.byType(DropdownButton<String>).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ANDRE VILELA GOUVEIA').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('1 linha(s)'), findsOneWidget);
      expect(find.text('HERBICIDA BORAL FULL 20L'), findsNothing);

      // Cascata: o dropdown de produto lista apenas produtos do cooperado
      // selecionado (não mostra os produtos dos demais cooperados).
      await tester.tap(find.byType(DropdownButton<String>).at(3));
      await tester.pumpAndSettle();
      // Card do item + opção no dropdown aberto.
      expect(find.text('HERBICIDA PROVENCE TOTAL 10L'), findsNWidgets(2));
      expect(find.text('HERBICIDA BORAL 500 SC 20L'), findsNothing);
      expect(find.text('HERBICIDA BORAL FULL 20L'), findsNothing);
      await tester.tap(find.text('HERBICIDA PROVENCE TOTAL 10L').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('1 linha(s)'), findsOneWidget);

      // Cascata inversa: com o produto selecionado, o dropdown de cooperado
      // só lista quem tem aquele produto.
      await tester.tap(find.byType(DropdownButton<String>).at(2));
      await tester.pumpAndSettle();
      expect(find.text('BRAVO ARMAZENS GERAIS LTDA'), findsNothing);
      await tester.tap(find.text('Todos').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('1 linha(s)'), findsOneWidget);
    }, () => MockClient((request) async => _tursoResponse()));
  });

  test('formatQuantidade usa separador de milhar', () {
    expect(formatQuantidade(23), '23');
    expect(formatQuantidade(1949), '1.949');
    expect(formatQuantidade(1234567), '1.234.567');
    expect(formatQuantidade(10.5), '10,50');
  });

  test('formatData converte ISO para dd/mm/yyyy', () {
    expect(formatData('2026-04-08'), '08/04/2026');
    expect(formatData('08/04/2026'), '08/04/2026');
  });
}
