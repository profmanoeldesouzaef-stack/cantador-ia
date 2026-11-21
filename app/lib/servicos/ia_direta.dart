import 'dart:convert';

import 'package:http/http.dart' as http;

import '../nucleo/escansao.dart';
import '../nucleo/lista_negra.dart';
import '../nucleo/prompt.dart';

/// Modo direto: o app chama Gemini/Claude com as chaves que o dono do celular cadastrou
/// em Ajustes. Mesma lógica do backend (regenera até 3 vezes se aparecer palavra proibida).
class IaDireta {
  static const geminiModelo = 'gemini-2.5-flash';
  static const claudeModelo = 'claude-sonnet-5-5';
  static const _maxTentativas = 3;

  static Future<String> _gemini(String chave, Prompt p) async {
    final r = await http
        .post(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$geminiModelo:generateContent'),
          headers: {'Content-Type': 'application/json', 'x-goog-api-key': chave},
          body: jsonEncode({
            'systemInstruction': {
              'parts': [
                {'text': p.sistema}
              ]
            },
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': p.usuario}
                ]
              }
            ],
            'generationConfig': {'temperature': 0.95, 'responseMimeType': 'application/json'},
          }),
        )
        .timeout(const Duration(seconds: 90));
    if (r.statusCode != 200) throw Exception('Gemini ${r.statusCode}: ${_resumo(r.body)}');
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map;
    final partes = (((j['candidates'] as List?)?.first as Map?)?['content'] as Map?)?['parts'] as List? ?? [];
    return partes.map((e) => (e as Map)['text'] ?? '').join();
  }

  static Future<String> _claude(String chave, Prompt p) async {
    final r = await http
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': chave,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': claudeModelo,
            'max_tokens': 2000,
            'system': p.sistema,
            'messages': [
              {'role': 'user', 'content': p.usuario}
            ],
          }),
        )
        .timeout(const Duration(seconds: 90));
    if (r.statusCode != 200) throw Exception('Claude ${r.statusCode}: ${_resumo(r.body)}');
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map;
    return ((j['content'] as List?) ?? []).map((e) => (e as Map)['text'] ?? '').join();
  }

  static String _resumo(String corpo) => corpo.length > 200 ? corpo.substring(0, 200) : corpo;

  static Map<String, dynamic> _extrairJson(String bruto) {
    final ini = bruto.indexOf('{');
    final fim = bruto.lastIndexOf('}');
    if (ini < 0 || fim < ini) throw Exception('a IA não devolveu JSON');
    final obj = Map<String, dynamic>.from(jsonDecode(bruto.substring(ini, fim + 1)) as Map);
    if (obj['secoes'] is! List) throw Exception('JSON sem seções');
    return obj;
  }

  static String _textoTodo(Map<String, dynamic> l) => [
        l['titulo']?.toString() ?? '',
        for (final s in l['secoes'] as List)
          for (final x in ((s as Map)['linhas'] as List? ?? [])) (x as Map)['texto']?.toString() ?? '',
      ].join('\n');

  /// Gera a letra e devolve no mesmo formato do backend.
  /// [ordem] lista as IAs a tentar ('gemini', 'claude'); [chaves] tem a chave de cada uma.
  static Future<Map<String, dynamic>> compor({
    required List<String> ordem,
    required Map<String, String> chaves,
    required String forma,
    required String toque,
    required String linhagem,
    required String tema,
    required List<String> palavrasChave,
    required List<String> listaNegra,
    required String notasDeEstilo,
    required List<String> exemplos,
  }) async {
    final base = montarPrompt(
      forma: forma,
      toque: toque,
      linhagem: linhagem,
      tema: tema,
      palavrasChave: palavrasChave,
      listaNegra: listaNegra,
      notasDeEstilo: notasDeEstilo,
      exemplos: exemplos,
    );
    final erros = <String>[];
    for (final ia in ordem) {
      final chave = chaves[ia] ?? '';
      if (chave.isEmpty) {
        erros.add('$ia: sem chave cadastrada');
        continue;
      }
      try {
        var correcao = '';
        Map<String, dynamic> letra = {};
        var achados = <String>[];
        var tentativas = 0;
        while (tentativas < _maxTentativas) {
          tentativas++;
          final p = Prompt(base.sistema, base.usuario + correcao);
          final bruto = ia == 'claude' ? await _claude(chave, p) : await _gemini(chave, p);
          letra = _extrairJson(bruto);
          achados = encontrarProibidas(_textoTodo(letra), listaNegra);
          if (achados.isEmpty) break;
          correcao = '\n\nATENÇÃO: na versão anterior apareceram palavras proibidas (${achados.join(', ')}). '
              'Componha de novo sem elas.';
        }
        final secoes = [
          for (final s in letra['secoes'] as List)
            {
              'tipo': (s as Map)['tipo']?.toString() ?? 'corrido',
              'linhas': [
                for (final l in (s['linhas'] as List? ?? []))
                  if (((l as Map)['texto']?.toString() ?? '').trim().isNotEmpty)
                    () {
                      final texto = l['texto'].toString().trim();
                      final e = escandir(texto);
                      final alvo = alvoDeSilabas(s['tipo']?.toString() ?? '');
                      return {
                        'voz': l['voz'] == 'coro' ? 'coro' : 'solo',
                        'texto': texto,
                        'silabas': e.silabas,
                        'rima': e.rima,
                        'foraDoAlvo': alvo != null && (e.silabas - alvo).abs() > 1,
                      };
                    }(),
              ],
            },
        ];
        return {
          'titulo': letra['titulo']?.toString() ?? 'Sem título',
          'secoes': secoes,
          'ia': ia,
          'tentativas': tentativas,
          'palavrasProibidasEncontradas': achados,
        };
      } catch (e) {
        erros.add('$ia: $e');
      }
    }
    throw Exception(erros.join('\n'));
  }
}
