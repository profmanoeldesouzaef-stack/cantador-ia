// Escansão poética heurística para português brasileiro.
// Conta sílabas até a última tônica do verso, com sinalefa entre palavras.
// É um guia para o compositor: hiato/ditongo dependem da pronúncia cantada.

const VOGAIS = "aeiouáàâãéêíóôõúüy";
const ACENTO_TONICO = "áéíóúâêô";
const NASAL = "ãõ";

const ehVogal = (c: string) => c !== "" && VOGAIS.includes(c);
const limpar = (w: string) => w.toLowerCase().replace(/[^a-zçáàâãéêíóôõúüy]/g, "");
const semAcento = (s: string) => s.normalize("NFD").replace(/[̀-ͯ]/g, "");

interface Nucleo {
  grupo: string;
  inicio: number;
}

/** Núcleos silábicos da palavra (grupo vocálico e posição onde começa). */
export function nucleos(palavra: string): Nucleo[] {
  const p = limpar(palavra);
  const res: Nucleo[] = [];
  let atual: Nucleo | null = null;
  for (let i = 0; i < p.length; i++) {
    const c = p[i];
    const ant = p[i - 1] ?? "";
    // "u" depois de q/g antes de vogal (quando, guerra): não abre núcleo.
    if ((c === "u" || c === "ü") && (ant === "q" || ant === "g") && ehVogal(p[i + 1] ?? "")) {
      if (atual) {
        res.push(atual);
        atual = null;
      }
      continue;
    }
    if (!ehVogal(c)) {
      if (atual) res.push(atual);
      atual = null;
      continue;
    }
    if (!atual) {
      atual = { grupo: c, inicio: i };
      continue;
    }
    const ultima: string = atual.grupo[atual.grupo.length - 1];
    const semivogal =
      // ditongo decrescente: vogal + i/u átonos (pai, céu, muito, ouro)
      ((c === "i" || c === "u") && ultima !== c && atual.grupo.length === 1) ||
      // ditongos nasais: ão, ãe, õe
      (NASAL.includes(ultima) && (c === "o" || c === "e"));
    if (semivogal) {
      atual.grupo += c;
    } else {
      res.push(atual);
      atual = { grupo: c, inicio: i };
    }
  }
  if (atual) res.push(atual);
  return res;
}

/** Índice (0-based) do núcleo tônico. */
export function indiceTonico(palavra: string): number {
  const ns = nucleos(palavra);
  if (ns.length <= 1) return 0;
  const comAcento = ns.findIndex((n) => [...n.grupo].some((c) => ACENTO_TONICO.includes(c)));
  if (comAcento >= 0) return comAcento;
  const nasal = ns.findIndex((n) => [...n.grupo].some((c) => NASAL.includes(c)));
  if (nasal >= 0) return nasal;
  // Paroxítonas: terminam em a, e, o (com ou sem s), am, em, ens.
  if (/([aeo]s?|am|em|ens)$/.test(limpar(palavra))) return ns.length - 2;
  return ns.length - 1;
}

function palavrasDo(verso: string): string[] {
  return verso
    .toLowerCase()
    .split(/[\s\-–—,.;:!?"'()]+/)
    .map(limpar)
    .filter((w) => nucleos(w).length > 0);
}

const comecaComVogal = (w: string) => ehVogal((w.startsWith("h") ? w.slice(1) : w)[0] ?? "");

function terminaComVogalAtona(w: string): boolean {
  const ult = w[w.length - 1] ?? "";
  return ehVogal(ult) && !ACENTO_TONICO.includes(ult) && !NASAL.includes(ult);
}

export interface Escansao {
  silabas: number;
  rima: string;
}

export function escandir(verso: string): Escansao {
  const ws = palavrasDo(verso);
  if (ws.length === 0) return { silabas: 0, rima: "" };
  let total = 0;
  ws.forEach((w, i) => {
    total += i === ws.length - 1 ? indiceTonico(w) + 1 : nucleos(w).length;
    if (i > 0 && terminaComVogalAtona(ws[i - 1]) && comecaComVogal(w)) total -= 1; // sinalefa
  });
  return { silabas: total, rima: rimaDe(ws[ws.length - 1]) };
}

/** Terminação a partir da vogal tônica da última palavra, sem acentos. */
export function rimaDe(palavra: string): string {
  const p = limpar(palavra);
  const ns = nucleos(p);
  if (ns.length === 0) return "";
  return semAcento(p.slice(ns[indiceTonico(p)].inicio));
}
