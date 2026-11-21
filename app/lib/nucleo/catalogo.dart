// Opções do compositor. As chaves batem com o backend (prompt.ts).

class Opcao {
  final String chave;
  final String nome;
  final String descricao;
  const Opcao(this.chave, this.nome, this.descricao);
}

const formas = [
  Opcao('ladainha', 'Ladainha + Chula', 'Narrativa solo de abertura, seguida da louvação.'),
  Opcao('quadra', 'Quadra', 'Estrofes de 4 versos (Regional), emendando num corrido.'),
  Opcao('corrido', 'Corrido', 'Solo curto e coro fixo, durante o jogo.'),
];

const toques = [
  Opcao('angola', 'Angola', 'Lento, jogo baixo, mandinga.'),
  Opcao('sao_bento_pequeno', 'São Bento Pequeno', 'Médio, Angola mais solto.'),
  Opcao('sao_bento_grande_angola', 'São Bento Grande de Angola', 'Mais rápido, conceito Angola.'),
  Opcao('sao_bento_grande_regional', 'São Bento Grande (Regional)', 'Rápido, jogo alto.'),
  Opcao('benguela', 'Benguela', 'Cadenciado, jogo baixo e de contato.'),
];

const linhagens = [
  Opcao('livre', 'Livre', 'A IA escolhe o estilo que melhor serve ao tema.'),
  Opcao('regional', 'Regional (Mestre Bimba)', 'Quadras e corridos diretos.'),
  Opcao('angola', 'Angola', 'Ladainhas de fundamento e ancestralidade.'),
  Opcao('contemporanea', 'Contemporânea (Mestre Camisa)', 'Angola e Regional juntas, linguagem atual.'),
];

const ias = [
  Opcao('auto', 'Automático', 'Usa a IA que você mais aprovou; se falhar, tenta a outra.'),
  Opcao('gemini', 'Gemini', 'Google. Tem nível gratuito.'),
  Opcao('claude', 'Claude', 'Anthropic. Pago, mais caprichado em poesia.'),
];

/// Aviso quando a combinação foge da tradição (não bloqueia: todos os estilos são permitidos).
String? avisoDeCombinacao(String forma, String toque) {
  final regional = toque == 'sao_bento_grande_regional' || toque == 'benguela';
  if (forma == 'ladainha' && regional) {
    return 'Ladainha é mais da tradição Angola. Na Regional, a abertura costuma ser a quadra.';
  }
  if (forma == 'quadra' && !regional) {
    return 'Quadra é a abertura da Regional. Nos toques de Angola, o costume é a ladainha.';
  }
  return null;
}

const avisoIuna = 'Iúna não aparece: é toque instrumental, sem canto.';

String nomeDa(List<Opcao> lista, String chave) =>
    lista.firstWhere((o) => o.chave == chave, orElse: () => lista.first).nome;

const nomesSecao = {
  'ladainha': 'Ladainha',
  'chula': 'Chula',
  'quadra': 'Quadra',
  'corrido': 'Corrido',
};
