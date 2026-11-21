import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../modelos.dart';
import '../nucleo/lista_negra.dart';

/// Tudo fica no celular: caderno, lista negra, preferências e o "aprendizado".
class Armazenamento {
  Armazenamento._(this._p);
  final SharedPreferences _p;

  static Future<Armazenamento> abrir() async => Armazenamento._(await SharedPreferences.getInstance());

  // ---------- Lista negra ----------
  List<String> get listaNegra => _p.getStringList('listaNegra') ?? List.of(listaNegraPadrao);
  Future<void> salvarListaNegra(List<String> l) => _p.setStringList('listaNegra', l);

  Future<void> adicionarProibidas(Iterable<String> novas) {
    final atual = listaNegra;
    final normAtual = atual.map(normalizar).toSet();
    for (final n in novas) {
      final t = n.trim();
      if (t.isNotEmpty && !normAtual.contains(normalizar(t))) {
        atual.add(t);
        normAtual.add(normalizar(t));
      }
    }
    return salvarListaNegra(atual);
  }

  // ---------- Chaves das IAs (ficam só neste aparelho) ----------
  String get chaveGemini => _p.getString('chaveGemini') ?? '';
  String get chaveClaude => _p.getString('chaveClaude') ?? '';
  Future<void> salvarChaveGemini(String v) => _p.setString('chaveGemini', v.trim());
  Future<void> salvarChaveClaude(String v) => _p.setString('chaveClaude', v.trim());
  Map<String, String> get chaves => {'gemini': chaveGemini, 'claude': chaveClaude};

  // ---------- Preferências ----------
  String get ia => _p.getString('ia') ?? 'auto';
  Future<void> salvarIa(String v) => _p.setString('ia', v);

  String get notasDeEstilo => _p.getString('notasDeEstilo') ?? '';
  Future<void> salvarNotas(String v) => _p.setString('notasDeEstilo', v);

  Future<void> anotarCritica(String critica) {
    final c = critica.trim();
    if (c.isEmpty) return Future.value();
    final atual = notasDeEstilo.trim();
    return salvarNotas(atual.isEmpty ? '- Evitar: $c' : '$atual\n- Evitar: $c');
  }

  // ---------- Votos por IA (o modo automático escolhe a mais aprovada) ----------
  int votos(String ia, int sinal) => _p.getInt('votos_${ia}_${sinal > 0 ? 'pos' : 'neg'}') ?? 0;

  Future<void> registrarVoto(String ia, int sinal) async {
    if (ia.isEmpty || sinal == 0) return;
    final k = 'votos_${ia}_${sinal > 0 ? 'pos' : 'neg'}';
    await _p.setInt(k, (_p.getInt(k) ?? 0) + 1);
  }

  /// Taxa de aprovação (0–1) ou null com menos de 5 votos.
  double? aprovacao(String ia) {
    final pos = votos(ia, 1), neg = votos(ia, -1);
    if (pos + neg < 5) return null;
    return pos / (pos + neg);
  }

  /// IA a pedir ao backend. Em "auto", com votos suficientes, fica com a mais aprovada.
  String iaEfetiva() {
    if (ia != 'auto') return ia;
    final g = aprovacao('gemini'), c = aprovacao('claude');
    if (g == null || c == null) return 'auto';
    return c > g ? 'claude' : 'gemini';
  }

  // ---------- Caderno ----------
  List<Letra> get caderno {
    final bruto = _p.getString('caderno');
    if (bruto == null) return [];
    try {
      return (jsonDecode(bruto) as List)
          .map((e) => Letra.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _gravarCaderno(List<Letra> l) =>
      _p.setString('caderno', jsonEncode(l.map((e) => e.toJson()).toList()));

  Future<void> salvarLetra(Letra letra) {
    final l = caderno;
    final i = l.indexWhere((e) => e.id == letra.id);
    if (i >= 0) {
      l[i] = letra;
    } else {
      l.insert(0, letra);
    }
    return _gravarCaderno(l);
  }

  Future<void> apagarLetra(String id) => _gravarCaderno(caderno..removeWhere((e) => e.id == id));

  /// Até 3 letras aprovadas da mesma forma, as mais recentes: viram referência de gosto para a IA.
  List<String> exemplosAprovados(String forma) => caderno
      .where((l) => l.avaliacao > 0 && l.forma == forma)
      .take(3)
      .map((l) => l.textoSimples(comCabecalho: false))
      .toList();
}
