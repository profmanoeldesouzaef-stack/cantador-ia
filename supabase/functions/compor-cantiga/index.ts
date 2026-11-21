// Supabase Edge Function: compor-cantiga
// Recebe os parâmetros do app, chama Gemini e/ou Claude, valida a lista negra
// (regenerando até 3 vezes) e devolve a letra com escansão por verso.
//
// Segredos (supabase secrets set ...):
//   GEMINI_API_KEY     chave do Google AI Studio (nível gratuito)
//   ANTHROPIC_API_KEY  chave da API do Claude (paga)
//   GEMINI_MODEL       opcional, padrão gemini-2.5-flash
//   CLAUDE_MODEL       opcional, padrão claude-sonnet-5-5

import { encontrarProibidas, LISTA_NEGRA_PADRAO, type Ocorrencia } from "./nucleo/listaNegra.ts";
import { escandir } from "./nucleo/escansao.ts";
import { FORMAS, LINHAGENS, montarPrompt, TOQUES, type Pedido } from "./nucleo/prompt.ts";

type Provedor = "gemini" | "claude";
type Escolha = Provedor | "auto";

interface Linha {
  voz: "solo" | "coro";
  texto: string;
}
interface Secao {
  tipo: string;
  linhas: Linha[];
}
interface Letra {
  titulo: string;
  secoes: Secao[];
}

const MAX_TENTATIVAS = 3;
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function resposta(corpo: unknown, status = 200) {
  return new Response(JSON.stringify(corpo), {
    status,
    headers: { ...CORS, "Content-Type": "application/json; charset=utf-8" },
  });
}

function texto(v: unknown, max: number): string {
  return typeof v === "string" ? v.slice(0, max) : "";
}
function listaDeTextos(v: unknown, maxItens: number, maxTam: number): string[] {
  return Array.isArray(v) ? v.filter((x) => typeof x === "string" && x.trim()).slice(0, maxItens).map((x) => x.slice(0, maxTam)) : [];
}

function lerPedido(b: Record<string, unknown>): Pedido | string {
  const forma = b.forma as Pedido["forma"];
  const toque = b.toque as Pedido["toque"];
  const linhagem = (b.linhagem ?? "livre") as Pedido["linhagem"];
  if (!(forma in FORMAS)) return "forma inválida";
  if (!(toque in TOQUES)) return "toque inválido";
  if (!(linhagem in LINHAGENS)) return "linhagem inválida";
  const listaNegra = Array.isArray(b.listaNegra) ? listaDeTextos(b.listaNegra, 200, 40) : LISTA_NEGRA_PADRAO;
  return {
    forma,
    toque,
    linhagem,
    tema: texto(b.tema, 300),
    palavrasChave: listaDeTextos(b.palavrasChave, 20, 40),
    listaNegra,
    notasDeEstilo: texto(b.notasDeEstilo, 1500),
    exemplos: listaDeTextos(b.exemplos, 3, 1500),
  };
}

function extrairJson(bruto: string): Letra {
  const ini = bruto.indexOf("{");
  const fim = bruto.lastIndexOf("}");
  if (ini < 0 || fim < ini) throw new Error("a IA não devolveu JSON");
  const obj = JSON.parse(bruto.slice(ini, fim + 1));
  if (!Array.isArray(obj.secoes)) throw new Error("JSON sem seções");
  return {
    titulo: String(obj.titulo ?? "Sem título"),
    secoes: obj.secoes.map((s: Secao) => ({
      tipo: String(s.tipo ?? "corrido"),
      linhas: (Array.isArray(s.linhas) ? s.linhas : [])
        .map((l: Linha): Linha => ({ voz: l.voz === "coro" ? "coro" : "solo", texto: String(l.texto ?? "").trim() }))
        .filter((l: Linha) => l.texto),
    })),
  };
}

async function chamarGemini(sistema: string, usuario: string): Promise<string> {
  const chave = Deno.env.get("GEMINI_API_KEY");
  if (!chave) throw new Error("GEMINI_API_KEY não configurada");
  const modelo = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.5-flash";
  const r = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${modelo}:generateContent`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-goog-api-key": chave },
    body: JSON.stringify({
      systemInstruction: { parts: [{ text: sistema }] },
      contents: [{ role: "user", parts: [{ text: usuario }] }],
      generationConfig: { temperature: 0.95, responseMimeType: "application/json" },
    }),
  });
  if (!r.ok) throw new Error(`Gemini ${r.status}: ${(await r.text()).slice(0, 300)}`);
  const j = await r.json();
  return (j.candidates?.[0]?.content?.parts ?? []).map((p: { text?: string }) => p.text ?? "").join("");
}

async function chamarClaude(sistema: string, usuario: string): Promise<string> {
  const chave = Deno.env.get("ANTHROPIC_API_KEY");
  if (!chave) throw new Error("ANTHROPIC_API_KEY não configurada");
  const modelo = Deno.env.get("CLAUDE_MODEL") ?? "claude-sonnet-5-5";
  const r = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-api-key": chave, "anthropic-version": "2023-06-01" },
    body: JSON.stringify({
      model: modelo,
      max_tokens: 2000,
      system: sistema,
      messages: [{ role: "user", content: usuario }],
    }),
  });
  if (!r.ok) throw new Error(`Claude ${r.status}: ${(await r.text()).slice(0, 300)}`);
  const j = await r.json();
  return (j.content ?? []).map((c: { text?: string }) => c.text ?? "").join("");
}

const CHAMADAS: Record<Provedor, typeof chamarGemini> = { gemini: chamarGemini, claude: chamarClaude };

function textoCompleto(l: Letra): string {
  return [l.titulo, ...l.secoes.flatMap((s) => s.linhas.map((x) => x.texto))].join("\n");
}

async function gerar(pedido: Pedido, provedor: Provedor) {
  const { sistema, usuario } = montarPrompt(pedido);
  let correcao = "";
  let letra: Letra | null = null;
  let achados: Ocorrencia[] = [];
  let tentativas = 0;
  while (tentativas < MAX_TENTATIVAS) {
    tentativas++;
    letra = extrairJson(await CHAMADAS[provedor](sistema, usuario + correcao));
    achados = encontrarProibidas(textoCompleto(letra), pedido.listaNegra);
    if (achados.length === 0) break;
    const lista = [...new Set(achados.map((a) => a.encontrado))].join(", ");
    correcao = `\n\nATENÇÃO: na versão anterior apareceram palavras proibidas (${lista}). Componha de novo sem elas.`;
  }
  return { letra: letra!, achados, tentativas };
}

const ALVO: Record<string, number | null> = { ladainha: 7, quadra: 7, chula: null, corrido: null };

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return resposta({ erro: "use POST" }, 405);

  let corpo: Record<string, unknown>;
  try {
    corpo = await req.json();
  } catch {
    return resposta({ erro: "JSON inválido" }, 400);
  }
  const pedido = lerPedido(corpo);
  if (typeof pedido === "string") return resposta({ erro: pedido }, 400);

  const escolha = (["gemini", "claude", "auto"].includes(String(corpo.ia)) ? corpo.ia : "auto") as Escolha;
  const ordem: Provedor[] = escolha === "auto" ? ["gemini", "claude"] : [escolha];

  const erros: string[] = [];
  for (const provedor of ordem) {
    try {
      const { letra, achados, tentativas } = await gerar(pedido, provedor);
      const secoes = letra.secoes.map((s) => ({
        tipo: s.tipo,
        linhas: s.linhas.map((l) => {
          const { silabas, rima } = escandir(l.texto);
          const alvo = ALVO[s.tipo] ?? null;
          return { ...l, silabas, rima, foraDoAlvo: alvo !== null && Math.abs(silabas - alvo) > 1 };
        }),
      }));
      return resposta({
        titulo: letra.titulo,
        secoes,
        ia: provedor,
        tentativas,
        palavrasProibidasEncontradas: [...new Set(achados.map((a) => a.encontrado))],
      });
    } catch (e) {
      erros.push(`${provedor}: ${(e as Error).message}`);
    }
  }
  return resposta({ erro: "Não consegui compor agora.", detalhes: erros }, 502);
});
