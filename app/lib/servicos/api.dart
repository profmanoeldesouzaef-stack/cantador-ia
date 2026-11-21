import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../modelos.dart';
import '../nucleo/lista_negra.dart';
import 'ia_direta.dart';

class ErroCompor implements Exception {
  final String mensagem;
  ErroCompor(this.mensagem);
  @override
  String toString() => mensagem;
}

class PedidoComposicao {
  final String forma, toque, linhagem, tema, ia, notasDeEstilo;
  final List<String> palavrasChave, listaNegra, exemplos;

  /// Chaves das IAs cadastradas no aparelho (modo direto). Nunca vão para o backend.
  final Map<String, String> chaves;

  PedidoComposicao({
    required this.forma,
    required this.toque,
    required this.linhagem,
    required this.tema,
    required this.ia,
    required this.palavrasChave,
    required this.listaNegra,
    required this.notasDeEstilo,
    required this.exemplos,
    this.chaves = const {},
  });

  Map<String, dynamic> toJson() => {
        'forma': forma,
        'toque': toque,
        'linhagem': linhagem,
        'tema': tema,
        'ia': ia,
        'palavrasChave': palavrasChave,
        'listaNegra': listaNegra,
        'notasDeEstilo': notasDeEstilo,
        'exemplos': exemplos,
      };
}

class Api {
  static Future<Letra> compor(PedidoComposicao p) async {
    final ordem = p.ia == 'auto' ? ['gemini', 'claude'] : [p.ia];
    final temChave = ordem.any((ia) => (p.chaves[ia] ?? '').isNotEmpty);
    if (temChave) return _direto(p, ordem);
    if (!backendConfigurado) {
      throw ErroCompor(p.ia == 'claude'
          ? 'Cadastre a chave do Claude em Ajustes para usar essa IA.'
          : 'Cadastre a chave do Gemini (gratuita) em Ajustes para começar a compor.');
    }
    return _servidor(p);
  }

  static Future<Letra> _direto(PedidoComposicao p, List<String> ordem) async {
    final Map<String, dynamic> corpo;
    try {
      corpo = await IaDireta.compor(
        ordem: ordem,
        chaves: p.chaves,
        forma: p.forma,
        toque: p.toque,
        linhagem: p.linhagem,
        tema: p.tema,
        palavrasChave: p.palavrasChave,
        listaNegra: p.listaNegra,
        notasDeEstilo: p.notasDeEstilo,
        exemplos: p.exemplos,
      );
    } catch (e) {
      throw ErroCompor('Não consegui compor agora.\n${e.toString().replaceFirst('Exception: ', '')}');
    }
    return _montar(corpo, p);
  }

  static Future<Letra> _servidor(PedidoComposicao p) async {
    final http.Response r;
    try {
      r = await http
          .post(
            Uri.parse('$supabaseUrl/functions/v1/compor-cantiga'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $supabaseAnonKey',
              'apikey': supabaseAnonKey,
            },
            body: jsonEncode(p.toJson()),
          )
          .timeout(const Duration(seconds: 90));
    } catch (_) {
      throw ErroCompor('Sem conexão com o servidor. Confira a internet e tente de novo.');
    }
    final corpo = _json(utf8.decode(r.bodyBytes));
    if (r.statusCode != 200) {
      final detalhe = (corpo['detalhes'] as List?)?.join('\n') ?? '';
      throw ErroCompor('${corpo['erro'] ?? 'Erro ${r.statusCode}'}${detalhe.isEmpty ? '' : '\n$detalhe'}');
    }
    return _montar(corpo, p);
  }

  static Letra _montar(Map<String, dynamic> corpo, PedidoComposicao p) {
    final letra = Letra.fromJson({
      ...corpo,
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'forma': p.forma,
      'toque': p.toque,
      'linhagem': p.linhagem,
      'tema': p.tema,
      'criadaEm': DateTime.now().toIso8601String(),
    });
    // Terceira camada: confere de novo no aparelho, com a lista que está no celular agora.
    letra.proibidasEncontradas = encontrarProibidas(letra.textoParaFiltro, p.listaNegra);
    return letra;
  }

  static Map<String, dynamic> _json(String s) {
    try {
      return Map<String, dynamic>.from(jsonDecode(s) as Map);
    } catch (_) {
      return {'erro': 'Resposta inválida do servidor'};
    }
  }
}
