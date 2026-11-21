// Filtro de palavras proibidas. Ignora maiúsculas/acentos e pega variações.
// A mesma regra existe em Dart (app/lib/nucleo/lista_negra.dart): mantenha as duas iguais.

export const LISTA_NEGRA_PADRAO = ["axé", "terreiro", "camarada", "camaradinha", "camará"];

export function normalizar(texto: string): string {
  return texto
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "");
}

const LETRA = "a-z0-9";

/** Regex que casa o termo proibido e suas variações, sobre texto já normalizado. */
export function padraoDoTermo(termo: string): RegExp | null {
  const t = normalizar(termo).trim().replace(/[^a-z0-9]/g, "");
  if (!t) return null;
  if (t.length >= 7) {
    // Radical: tira a vogal final e aceita qualquer sufixo (plural, diminutivo, aumentativo).
    const radical = /[aeo]$/.test(t) ? t.slice(0, -1) : t;
    return new RegExp(`(?<![${LETRA}])${radical}[${LETRA}]*`, "g");
  }
  // Termo curto: palavra exata + plural.
  return new RegExp(`(?<![${LETRA}])${t}(s|es)?(?![${LETRA}])`, "g");
}

export interface Ocorrencia {
  termo: string;
  encontrado: string;
}

export function encontrarProibidas(texto: string, lista: string[]): Ocorrencia[] {
  const norm = normalizar(texto);
  const achados: Ocorrencia[] = [];
  for (const termo of lista) {
    const re = padraoDoTermo(termo);
    if (!re) continue;
    for (const m of norm.matchAll(re)) {
      achados.push({ termo, encontrado: m[0] });
    }
  }
  return achados;
}
