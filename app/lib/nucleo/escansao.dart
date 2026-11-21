// Escansão poética heurística (porte de supabase/.../nucleo/escansao.ts — mantenha iguais).
// Conta sílabas até a última tônica do verso, com sinalefa entre palavras.

import 'lista_negra.dart' show normalizar;

const _vogais = 'aeiouáàâãéêíóôõúüy';
const _acentoTonico = 'áéíóúâêô';
const _nasal = 'ãõ';

bool _ehVogal(String c) => c.isNotEmpty && _vogais.contains(c);
String _limpar(String w) => w.toLowerCase().replaceAll(RegExp(r'[^a-zçáàâãéêíóôõúüy]'), '');

class _Nucleo {
  String grupo;
  final int inicio;
  _Nucleo(this.grupo, this.inicio);
}

List<_Nucleo> _nucleos(String palavra) {
  final p = _limpar(palavra);
  final res = <_Nucleo>[];
  _Nucleo? atual;
  String em(int i) => (i >= 0 && i < p.length) ? p[i] : '';
  for (var i = 0; i < p.length; i++) {
    final c = p[i];
    final ant = em(i - 1);
    if ((c == 'u' || c == 'ü') && (ant == 'q' || ant == 'g') && _ehVogal(em(i + 1))) {
      if (atual != null) res.add(atual);
      atual = null;
      continue;
    }
    if (!_ehVogal(c)) {
      if (atual != null) res.add(atual);
      atual = null;
      continue;
    }
    if (atual == null) {
      atual = _Nucleo(c, i);
      continue;
    }
    final ultima = atual.grupo[atual.grupo.length - 1];
    final semivogal = ((c == 'i' || c == 'u') && ultima != c && atual.grupo.length == 1) ||
        (_nasal.contains(ultima) && (c == 'o' || c == 'e'));
    if (semivogal) {
      atual.grupo += c;
    } else {
      res.add(atual);
      atual = _Nucleo(c, i);
    }
  }
  if (atual != null) res.add(atual);
  return res;
}

int _indiceTonico(String palavra) {
  final ns = _nucleos(palavra);
  if (ns.length <= 1) return 0;
  bool tem(_Nucleo n, String chars) => n.grupo.split('').any(chars.contains);
  final comAcento = ns.indexWhere((n) => tem(n, _acentoTonico));
  if (comAcento >= 0) return comAcento;
  final nasal = ns.indexWhere((n) => tem(n, _nasal));
  if (nasal >= 0) return nasal;
  if (RegExp(r'([aeo]s?|am|em|ens)$').hasMatch(_limpar(palavra))) return ns.length - 2;
  return ns.length - 1;
}

class Escansao {
  final int silabas;
  final String rima;
  const Escansao(this.silabas, this.rima);
}

Escansao escandir(String verso) {
  final ws = verso
      .toLowerCase()
      .split(RegExp(r'''[\s\-–—,.;:!?"'()]+'''))
      .map(_limpar)
      .where((w) => _nucleos(w).isNotEmpty)
      .toList();
  if (ws.isEmpty) return const Escansao(0, '');
  var total = 0;
  for (var i = 0; i < ws.length; i++) {
    final w = ws[i];
    total += i == ws.length - 1 ? _indiceTonico(w) + 1 : _nucleos(w).length;
    if (i > 0) {
      final ant = ws[i - 1];
      final ult = ant[ant.length - 1];
      final atonaNoFim = _ehVogal(ult) && !_acentoTonico.contains(ult) && !_nasal.contains(ult);
      final inicio = w.startsWith('h') ? w.substring(1) : w;
      if (atonaNoFim && inicio.isNotEmpty && _ehVogal(inicio[0])) total -= 1; // sinalefa
    }
  }
  return Escansao(total, rimaDe(ws.last));
}

String rimaDe(String palavra) {
  final p = _limpar(palavra);
  final ns = _nucleos(p);
  if (ns.isEmpty) return '';
  return normalizar(p.substring(ns[_indiceTonico(p)].inicio));
}

/// Alvo de sílabas por tipo de seção (null = sem alvo).
int? alvoDeSilabas(String tipo) => (tipo == 'ladainha' || tipo == 'quadra') ? 7 : null;
