import 'package:estocados_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nomeDoPalete bate com o nome que o Gôndolas grava', () {
    expect(nomeDoPalete('ADUBO 5L', 'MARIA'), 'ADUBO 5L · MARIA');
  });

  test('montarEnderecos junta galpão e barracão pelo nome do palete', () {
    final mapa = montarEnderecos(
      galpao: [
        {'posicao': '40', 'ordem': '4', 'produto_nome': 'ADUBO 5L · MARIA'},
        {'posicao': '', 'ordem': '1', 'produto_nome': 'X'},
      ],
      barracao: [
        {'rotulo': 'BAR-07', 'produto_nome': 'ADUBO 5L · MARIA'},
      ],
    );
    expect(mapa.keys, ['ADUBO 5L · MARIA']);
    expect(mapa['ADUBO 5L · MARIA'], ['Galpão 40 · N4', 'BAR-07']);
  });
}
