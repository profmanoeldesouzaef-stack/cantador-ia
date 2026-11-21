import 'package:cantador/nucleo/lista_negra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String> achar(String t) => encontrarProibidas(t, listaNegraPadrao);

  test('pega maiúscula e sem acento', () => expect(achar('Muito AXÉ'), ['axe']));
  test('pega plural', () => expect(achar('os axés'), ['axes']));
  test('não pega peixe', () => expect(achar('Peixe na maré'), isEmpty));
  test('pega família camarada', () => expect(achar('meus camaradas'), ['camaradas']));
  test('pega terreirão', () => expect(achar('no terreirão'), ['terreirao']));
  test('pega camará', () => expect(achar('viva meu Deus, camará'), ['camara']));
  test('limpo', () => expect(achar('Berimbau tocou na beira do mar'), isEmpty));
  test('palavras removidas na edição', () {
    expect(palavrasRemovidas('O vento forte na maré', 'O vento na maré'), ['forte']);
  });
}
