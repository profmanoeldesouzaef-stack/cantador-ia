import 'package:cantador/nucleo/escansao.dart';
import 'package:cantador/nucleo/prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Redondilha maior de domínio público (Gonçalves Dias, 1843): mesmos casos do backend.
  test('Minha terra tem palmeiras', () => expect(escandir('Minha terra tem palmeiras').silabas, 7));
  test('Onde canta o sabiá', () => expect(escandir('Onde canta o sabiá').silabas, 7));
  test('As aves que aqui gorjeiam', () => expect(escandir('As aves que aqui gorjeiam').silabas, 7));
  test('Não gorjeiam como lá', () => expect(escandir('Não gorjeiam como lá').silabas, 7));
  test('chula', () => expect(escandir('Iê, viva meu Deus').silabas, 6));
  test('Bahia', () => expect(escandir('Quando eu vim da Bahia').silabas, 6));
  test('rimas', () {
    expect(rimaDe('maré'), 'e');
    expect(rimaDe('cantar'), 'ar');
    expect(rimaDe('berimbau'), 'au');
    expect(rimaDe('Bahia'), 'ia');
    expect(rimaDe('coração'), 'ao');
  });
  test('prompt leva lista negra e palavras-chave', () {
    final p = montarPrompt(
      forma: 'ladainha',
      toque: 'angola',
      linhagem: 'angola',
      tema: 'maré cheia',
      palavrasChave: ['jangadeiro'],
      listaNegra: ['camará'],
      notasDeEstilo: '',
      exemplos: [],
    );
    expect(p.sistema.contains('"camará"'), isTrue);
    expect(p.usuario.contains('jangadeiro'), isTrue);
  });
}
