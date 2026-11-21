# Cantador IA — Especificação revisada (v2)

App mobile (Android primeiro, depois iOS) que compõe letras de músicas de capoeira por IA, respeitando a forma do canto, a cadência do toque, a linhagem escolhida e uma lista negra de palavras definida pelo compositor.

## 1. Decisões desta versão

| Tema | Decisão |
| :--- | :--- |
| App | Flutter, distribuído como APK Android no MVP |
| IA | **Duas:** Gemini (nível gratuito) e Claude (pago). Modo Automático usa a mais aprovada pelo compositor e cai na outra se a primeira falhar |
| Estilos | Todas as linhagens, formas e toques liberados. Combinação fora da tradição só gera aviso (Iúna segue fora: é instrumental) |
| Lapidação | 👍 salva a letra como referência de gosto (até 3 por forma vão no prompt); 👎 pede a crítica e ela vira preferência; palavras apagadas na edição podem ir para a lista negra com um toque; votos por IA definem o modo Automático |
| Chave da IA | Nunca no app. Fica num **backend intermediário** (Supabase Edge Function) |
| Armazenamento | Local no celular (Caderno de Músicas e lista negra). Sync em nuvem fica para depois |
| "Camará" | Entra bloqueada na lista padrão, junto com a família "camarada". O usuário pode liberar |

## 2. Modelo correto: forma do canto × toque × linhagem

A v1 misturava **forma de canto** com **toque de berimbau**. São coisas independentes.

### 2.1 Formas de canto
| Forma | Estrutura | Observação |
| :--- | :--- | :--- |
| **Ladainha** | Só solo, narrativa (8–16 versos, tendendo à redondilha maior, 7 sílabas), seguida da **chula** (louvação solo → coro repete) | Tradição Angola, abre a roda antes do jogo |
| **Quadra** | Estrofes de 4 versos cantadas pelo solista, emendando num corrido | Forma de abertura da Regional de Mestre Bimba |
| **Corrido** | Solo curto (1–2 versos, varia) + coro curto e fixo (repete igual) | Canta-se durante o jogo, em qualquer toque |

### 2.2 Toques
| Toque | Andamento / jogo | Formas aceitas |
| :--- | :--- | :--- |
| Angola | Lento, jogo baixo, malícia e fundamento | Ladainha, Corrido |
| São Bento Pequeno | Médio, jogo de Angola mais solto | Ladainha, Corrido |
| São Bento Grande de Angola | Mais rápido, ainda no conceito Angola | Ladainha, Corrido |
| São Bento Grande (Regional) | Rápido, jogo alto, objetividade | Quadra, Corrido |
| Benguela | Mais cadenciado, jogo baixo e de contato | Quadra, Corrido |
| **Iúna** | **Instrumental, sem canto** (formados, na Regional) | Nenhuma: aparece desabilitado com explicação |

### 2.3 Linhagem (referência estilística)
| Linhagem | Formas | Toques |
| :--- | :--- | :--- |
| Regional (Mestre Bimba) | Quadra, Corrido | São Bento Grande (Regional), Benguela |
| Angola | Ladainha, Corrido | Angola, São Bento Pequeno, São Bento Grande de Angola |
| Contemporânea (ex.: Mestre Camisa / Abadá) | Todas | Todos (exceto Iúna) |

O app só mostra combinações válidas. Escolher a linhagem filtra formas e toques.

## 3. Lista negra (filtro estrito)

- **Padrão pré-carregado:** `axé`, `terreiro`, `camarada`, `camaradinha`, `camará`. Editável.
- **Comparação:** ignora maiúsculas e acentos e pega variações:
  - Termos com 7+ letras: bloqueia o radical (sem a vogal final). `camarada` pega camaradas, camarado, camaradinha; `terreiro` pega terreiros, terreirão.
  - Termos curtos: palavra exata + plural (`axé` pega axe, axés).
  - Efeito colateral conhecido: `camará` também bloqueia "câmara" (mesma grafia sem acento).
- **Três camadas:** (1) o prompt proíbe; (2) o backend valida e regenera até 3 vezes; (3) o app valida de novo antes de exibir. Se ainda sobrar palavra proibida, o app **mostra destacado** em vez de esconder ou entrar em loop.

## 4. Métrica (escansão)

IA erra contagem de sílabas, então o backend faz **escansão poética** de cada verso:
sílabas até a última tônica, com elisão (sinalefa) entre vogais de palavras vizinhas. Também extrai a terminação de rima.

- Ladainha e quadra: alvo de 7 sílabas poéticas (aceita 6–8). Versos fora do alvo ficam sinalizados.
- Corrido: sem alvo fixo; mostra a contagem para o compositor ajustar.
- É **heurística**: hiatos e ditongos dependem da pronúncia cantada. Serve de guia, não de juiz.

## 5. Fluxo do usuário

1. **Compor:** linhagem → forma → toque → tema e palavras-chave obrigatórias → lista negra (chips editáveis).
2. **Gerar:** chamada ao backend. Tela de espera curta.
3. **Resultado:** seções (Ladainha / Chula / Quadra / Corrido), linhas marcadas **Solo** ou **Coro**, contagem de sílabas por verso, alerta de verso fora do alvo, alerta de palavra proibida.
4. **Ações:** Editar, Gerar variação (mesmos filtros), Copiar, Compartilhar (WhatsApp), Salvar no Caderno.
5. **Caderno:** lista das letras salvas, abrir, editar, apagar.

## 6. Arquitetura

```
App Flutter ──HTTPS (anon key)──> Supabase Edge Function "compor-cantiga"
                                     ├─ monta o prompt (forma × toque × linhagem)
                                     ├─ chama Gemini (saída JSON estruturada)
                                     ├─ valida lista negra → regenera (máx. 3)
                                     └─ escansão + rima → devolve JSON
```

Segredos no Supabase: `GEMINI_API_KEY` (obrigatório), `GEMINI_MODEL` (opcional).

## 7. Formato de resposta do backend

```json
{
  "titulo": "Maré cheia",
  "secoes": [
    { "tipo": "ladainha", "linhas": [ { "voz": "solo", "texto": "...", "silabas": 7, "rima": "ar", "foraDoAlvo": false } ] },
    { "tipo": "chula", "linhas": [ { "voz": "solo", "texto": "Iê, viva meu Deus" }, { "voz": "coro", "texto": "Iê, viva meu Deus" } ] }
  ],
  "palavrasProibidasEncontradas": [],
  "tentativas": 1
}
```

## 8. Prompt oficial

Fica em `supabase/functions/compor-cantiga/nucleo/prompt.ts`. Pontos-chave:
- Persona de mestre cantador com fundamento; descrição da forma e do toque escolhidos.
- Inclusão obrigatória do tema e das palavras-chave.
- Proibição das palavras da lista negra, **com variações**, e da chula com "camará" quando ela estiver bloqueada.
- **Originalidade:** proibido copiar cantigas existentes; domínio público só como referência de estilo.
- Saída somente em JSON no formato acima (o modelo não decide a escansão).

## 9. Fora do MVP (próximas etapas)

- Login e backup no Supabase (sync entre aparelhos).
- Exportar PDF.
- Limite de uso por aparelho/usuário no backend (proteger a cota gratuita).
- Gravação de voz / melodia de referência.
