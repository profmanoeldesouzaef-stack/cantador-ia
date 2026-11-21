import 'nucleo/catalogo.dart';

class Linha {
  String voz; // 'solo' | 'coro'
  String texto;
  int? silabas;
  bool foraDoAlvo;

  Linha({required this.voz, required this.texto, this.silabas, this.foraDoAlvo = false});

  factory Linha.fromJson(Map<String, dynamic> j) => Linha(
        voz: j['voz'] == 'coro' ? 'coro' : 'solo',
        texto: (j['texto'] ?? '').toString(),
        silabas: (j['silabas'] as num?)?.toInt(),
        foraDoAlvo: j['foraDoAlvo'] == true,
      );

  Map<String, dynamic> toJson() =>
      {'voz': voz, 'texto': texto, 'silabas': silabas, 'foraDoAlvo': foraDoAlvo};
}

class Secao {
  String tipo;
  List<Linha> linhas;

  Secao({required this.tipo, required this.linhas});

  factory Secao.fromJson(Map<String, dynamic> j) => Secao(
        tipo: (j['tipo'] ?? 'corrido').toString(),
        linhas: ((j['linhas'] as List?) ?? [])
            .map((l) => Linha.fromJson(Map<String, dynamic>.from(l as Map)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {'tipo': tipo, 'linhas': linhas.map((l) => l.toJson()).toList()};
}

class Letra {
  String id;
  String titulo;
  List<Secao> secoes;
  String forma;
  String toque;
  String linhagem;
  String tema;
  String ia;
  DateTime criadaEm;

  /// 1 = aprovada, -1 = reprovada, 0 = sem avaliação. Aprovadas viram referência de gosto.
  int avaliacao;
  List<String> proibidasEncontradas;

  Letra({
    required this.id,
    required this.titulo,
    required this.secoes,
    required this.forma,
    required this.toque,
    required this.linhagem,
    required this.tema,
    required this.ia,
    required this.criadaEm,
    this.avaliacao = 0,
    this.proibidasEncontradas = const [],
  });

  factory Letra.fromJson(Map<String, dynamic> j) => Letra(
        id: (j['id'] ?? DateTime.now().microsecondsSinceEpoch.toString()).toString(),
        titulo: (j['titulo'] ?? 'Sem título').toString(),
        secoes: ((j['secoes'] as List?) ?? [])
            .map((s) => Secao.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList(),
        forma: (j['forma'] ?? 'corrido').toString(),
        toque: (j['toque'] ?? 'angola').toString(),
        linhagem: (j['linhagem'] ?? 'livre').toString(),
        tema: (j['tema'] ?? '').toString(),
        ia: (j['ia'] ?? '').toString(),
        criadaEm: DateTime.tryParse((j['criadaEm'] ?? '').toString()) ?? DateTime.now(),
        avaliacao: (j['avaliacao'] as num?)?.toInt() ?? 0,
        proibidasEncontradas: ((j['palavrasProibidasEncontradas'] ?? j['proibidasEncontradas']) as List? ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'secoes': secoes.map((s) => s.toJson()).toList(),
        'forma': forma,
        'toque': toque,
        'linhagem': linhagem,
        'tema': tema,
        'ia': ia,
        'criadaEm': criadaEm.toIso8601String(),
        'avaliacao': avaliacao,
        'proibidasEncontradas': proibidasEncontradas,
      };

  Letra copia() => Letra.fromJson(toJson());

  /// Texto para copiar/compartilhar e para servir de exemplo à IA.
  String textoSimples({bool comCabecalho = true}) {
    final b = StringBuffer();
    if (comCabecalho) {
      b.writeln(titulo.toUpperCase());
      b.writeln('${nomeDa(formas, forma)} · ${nomeDa(toques, toque)}');
      b.writeln();
    }
    for (final s in secoes) {
      b.writeln('[${nomesSecao[s.tipo] ?? s.tipo}]');
      for (final l in s.linhas) {
        b.writeln(l.voz == 'coro' ? 'Coro: ${l.texto}' : l.texto);
      }
      b.writeln();
    }
    return b.toString().trim();
  }

  String get textoParaFiltro => [titulo, ...secoes.expand((s) => s.linhas.map((l) => l.texto))].join('\n');
}
