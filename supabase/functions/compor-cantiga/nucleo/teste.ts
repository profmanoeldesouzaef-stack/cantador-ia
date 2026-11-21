// Rodar: node --experimental-strip-types nucleo/teste.ts
import { escandir, rimaDe } from "./escansao.ts";
import { encontrarProibidas, LISTA_NEGRA_PADRAO } from "./listaNegra.ts";
import { montarPrompt } from "./prompt.ts";

let falhas = 0;
function igual<T>(obtido: T, esperado: T, nome: string) {
  const ok = JSON.stringify(obtido) === JSON.stringify(esperado);
  if (!ok) falhas++;
  console.log(`${ok ? "ok  " : "FALHOU"} ${nome}: ${JSON.stringify(obtido)}${ok ? "" : ` (esperado ${JSON.stringify(esperado)})`}`);
}

// Escansão: redondilha maior de domínio público (Gonçalves Dias, 1843)
igual(escandir("Minha terra tem palmeiras").silabas, 7, "palmeiras");
igual(escandir("Onde canta o sabiá").silabas, 7, "sabiá");
igual(escandir("As aves que aqui gorjeiam").silabas, 7, "gorjeiam");
igual(escandir("Não gorjeiam como lá").silabas, 7, "lá");
igual(escandir("Iê, viva meu Deus").silabas, 6, "chula");
igual(escandir("Quando eu vim da Bahia").silabas, 6, "Bahia");
igual(rimaDe("maré"), "e", "rima maré");
igual(rimaDe("cantar"), "ar", "rima cantar");
igual(rimaDe("berimbau"), "au", "rima berimbau");
igual(rimaDe("Bahia"), "ia", "rima Bahia");
igual(rimaDe("coração"), "ao", "rima coração");

// Lista negra
const L = LISTA_NEGRA_PADRAO;
const termos = (t: string) => encontrarProibidas(t, L).map((o) => o.encontrado);
igual(termos("Muito AXÉ pra você"), ["axe"], "axé maiúsculo");
igual(termos("os axés da roda"), ["axes"], "plural axés");
igual(termos("Machado não é axe-ado"), ["axe"], "axe com hífen");
igual(termos("Peixe na maré"), [], "não pega peixe");
igual(termos("meus camaradas vêm"), ["camaradas"], "camaradas");
igual(termos("Camaradinha, ê"), ["camaradinha", "camaradinha"], "camaradinha (2 termos)");
igual(termos("no terreirão"), ["terreirao"], "terreirão");
igual(termos("Iê, viva meu Deus, camará"), ["camara"], "camará");
igual(termos("Camaradagem"), ["camaradagem"], "camaradagem");
igual(termos("Berimbau tocou na beira do mar"), [], "limpo");

// Prompt
const p = montarPrompt({
  forma: "ladainha",
  toque: "angola",
  linhagem: "angola",
  tema: "maré cheia",
  palavrasChave: ["jangadeiro"],
  listaNegra: L,
  notasDeEstilo: "",
  exemplos: [],
});
igual(p.sistema.includes("camará"), true, "prompt cita camará");
igual(p.usuario.includes("jangadeiro"), true, "prompt cita palavra-chave");

console.log(falhas ? `\n${falhas} falha(s)` : "\nTudo certo");
if (falhas) throw new Error("testes falharam");
