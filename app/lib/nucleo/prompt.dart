// Prompt oficial (porte de supabase/.../nucleo/prompt.ts — mantenha os dois iguais).

const _formas = {
  'ladainha':
      'LADAINHA: só o solista canta. Narrativa de fundamento, história ou filosofia, de 8 a 16 versos, '
          'tendendo à redondilha maior (7 sílabas poéticas), rima nos versos pares. Abre com o grito "Iê!" numa linha própria. '
          'Depois vem a CHULA (louvação): o solista louva e o coro repete a louvação, linha a linha (ex.: "Iê, viva meu Deus" / coro repete).',
  'quadra': 'QUADRA: forma de abertura da Regional. Duas ou três estrofes de 4 versos cantadas pelo solista, '
      'redondilha maior (7 sílabas), rima nos versos pares. Emenda num CORRIDO curto no fim.',
  'corrido': 'CORRIDO: canto de diálogo durante o jogo. O CORO é curto (2 a 6 palavras), fixo e fácil de repetir; '
      'o SOLO é curto (1 ou 2 versos) e varia a cada chamada, desenvolvendo o tema. Alterne solo e coro, de 6 a 10 chamadas.',
};

const _toques = {
  'angola': 'Angola: andamento lento, jogo baixo, malícia, mandinga e fundamento. Canto grave e cadenciado.',
  'sao_bento_pequeno': 'São Bento Pequeno: andamento médio, jogo de Angola mais solto. Canto cadenciado.',
  'sao_bento_grande_angola': 'São Bento Grande de Angola: mais rápido, ainda no conceito Angola. Versos mais curtos.',
  'sao_bento_grande_regional':
      'São Bento Grande (Regional): rápido e vibrante, jogo alto e objetivo. Versos curtos, coro enérgico.',
  'benguela': 'Benguela: cadenciado, jogo baixo e de contato, técnica e controle. Canto melódico.',
};

const _linhagens = {
  'regional': 'Referência: tradição da Capoeira Regional de Mestre Bimba (quadras e corridos diretos, '
      'linguagem simples, valorização do treino e da disciplina).',
  'angola': 'Referência: tradição da Capoeira Angola (ladainhas de fundamento, ancestralidade, '
      'história dos antigos mestres, malícia).',
  'contemporanea': 'Referência: capoeira contemporânea, como a escola de Mestre Camisa (Abadá-Capoeira): '
      'fundamento, união de Angola e Regional, linguagem atual sem perder a tradição.',
  'livre': 'Referência: livre, escolha o estilo que melhor servir ao tema, ao toque e à forma.',
};

class Prompt {
  final String sistema;
  final String usuario;
  const Prompt(this.sistema, this.usuario);
}

Prompt montarPrompt({
  required String forma,
  required String toque,
  required String linhagem,
  required String tema,
  required List<String> palavrasChave,
  required List<String> listaNegra,
  required String notasDeEstilo,
  required List<String> exemplos,
}) {
  final proibidas = listaNegra.map((p) => '- "$p"').join('\n');
  final sistema = '''Você é um mestre cantador de capoeira, com fundamento nas tradições de Angola e Regional, que compõe cantigas inéditas para a roda.

REGRAS DE OFÍCIO
- Escreva em português do Brasil, com a oralidade da roda (pode usar "ê", "ô", "iê", "lê lê", "vamos vadiar"), mas sem caricatura.
- Versos curtos, cantáveis, com acento natural e rima. Pense no berimbau marcando o tempo.
- O coro precisa ser fácil de responder por quem nunca ouviu a música.
- Respeite a forma e o toque pedidos (descritos abaixo).

ORIGINALIDADE
- Componha algo NOVO. É proibido copiar ou parafrasear de perto cantigas existentes, de autoria conhecida ou não.
- Fórmulas tradicionais curtas da roda (como "Iê, viva meu Deus" na chula) podem ser usadas.

RESTRIÇÃO INVIOLÁVEL — PALAVRAS PROIBIDAS
Nunca escreva nenhuma das palavras abaixo, nem plural, diminutivo, aumentativo, forma sem acento ou derivado:
$proibidas
Se a fórmula tradicional usar uma delas (por exemplo, "camará" no fim da chula), troque por outra resposta ou repita o verso sem a palavra.
Antes de responder, releia cada verso procurando essas palavras.

FORMATO DE SAÍDA
Responda SOMENTE com JSON válido, sem comentários:
{"titulo": string, "secoes": [{"tipo": "ladainha"|"chula"|"quadra"|"corrido", "linhas": [{"voz": "solo"|"coro", "texto": string}]}]}
Cada verso é uma linha. Não numere versos.''';

  final ex = exemplos.isEmpty
      ? ''
      : '\n\nLETRAS QUE O COMPOSITOR APROVOU (use como referência de gosto e vocabulário, NÃO copie):\n'
          '${[for (var i = 0; i < exemplos.length; i++) '--- Exemplo ${i + 1} ---\n${exemplos[i]}'].join('\n')}';
  final notas = notasDeEstilo.trim().isEmpty ? '' : '\n\nPREFERÊNCIAS DO COMPOSITOR:\n${notasDeEstilo.trim()}';

  final usuario = '''Componha uma cantiga.

FORMA: ${_formas[forma] ?? _formas['corrido']}
TOQUE: ${_toques[toque] ?? _toques['angola']}
${_linhagens[linhagem] ?? _linhagens['livre']}

TEMA: ${tema.isEmpty ? 'livre' : tema}
PALAVRAS-CHAVE QUE DEVEM APARECER: ${palavrasChave.isEmpty ? 'nenhuma obrigatória' : palavrasChave.join(', ')}$notas$ex''';

  return Prompt(sistema, usuario);
}
