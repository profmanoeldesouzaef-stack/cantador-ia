// Filtro de palavras proibidas. Mesma regra do backend
// (supabase/functions/compor-cantiga/nucleo/listaNegra.ts): mantenha as duas iguais.

const listaNegraPadrao = ['axé', 'terreiro', 'camarada', 'camaradinha', 'camará'];

const _semAcento = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n',
};

String normalizar(String texto) {
  final b = StringBuffer();
  for (final c in texto.toLowerCase().split('')) {
    b.write(_semAcento[c] ?? c);
  }
  return b.toString();
}

RegExp? padraoDoTermo(String termo) {
  final t = normalizar(termo).trim().replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (t.isEmpty) return null;
  if (t.length >= 7) {
    final radical = RegExp(r'[aeo]$').hasMatch(t) ? t.substring(0, t.length - 1) : t;
    return RegExp('(?<![a-z0-9])$radical[a-z0-9]*');
  }
  return RegExp('(?<![a-z0-9])$t(s|es)?(?![a-z0-9])');
}

/// Devolve as formas proibidas encontradas (normalizadas, sem repetição).
List<String> encontrarProibidas(String texto, List<String> lista) {
  final norm = normalizar(texto);
  final achados = <String>{};
  for (final termo in lista) {
    final re = padraoDoTermo(termo);
    if (re == null) continue;
    for (final m in re.allMatches(norm)) {
      achados.add(m.group(0)!);
    }
  }
  return achados.toList();
}

/// Palavras (4+ letras) que existiam no original e o compositor apagou ao editar.
/// O app oferece bloquear essas palavras: é assim que a lista negra vai se lapidando.
List<String> palavrasRemovidas(String original, String editado) {
  Set<String> palavras(String s) => s
      .toLowerCase()
      .split(RegExp(r"[^a-zçáàâãéêíóôõúü]+"))
      .where((w) => w.length >= 4)
      .toSet();
  final depois = palavras(editado).map(normalizar).toSet();
  return palavras(original).where((w) => !depois.contains(normalizar(w))).toList()..sort();
}
