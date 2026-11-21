# Cantador IA — como rodar

```
cantador/
├── ESPECIFICACAO.md                      especificação revisada (fundamentos + arquitetura)
├── app/                                  app Flutter (Android)
└── supabase/functions/compor-cantiga/    backend: prompt, Gemini + Claude, lista negra, escansão
```

## 0. Jeito mais rápido: só o APK

1. Cada push na `main` faz o GitHub Actions gerar o APK. Ele aparece em **Releases** do repositório como `cantador-ia.apk`.
2. Baixe no celular e instale (permita "instalar apps desconhecidos").
3. No app, vá em **Ajustes** e cole a chave do Gemini (grátis em https://aistudio.google.com/apikey). A do Claude é opcional.

Nesse modo o app fala direto com as IAs, e a chave fica guardada só no seu celular. O backend abaixo
é para quando o app for distribuído para outras pessoas, porque aí a chave não pode ficar no aparelho.

Todo APK é assinado com a mesma chave (`app/assinatura/debug.keystore`), então a versão nova instala por cima
da antiga sem apagar o caderno. Para publicar na Play Store, troque por uma chave de release própria.

## 1. Backend (opcional, uma vez)

1. Crie um projeto no Supabase (o plano gratuito serve).
2. Pegue as chaves das IAs:
   - Gemini: https://aistudio.google.com/apikey (gratuita)
   - Claude: https://console.anthropic.com (paga; opcional, sem ela o app usa só Gemini)
3. No terminal, dentro da pasta `cantador`:
   ```bash
   npx supabase login
   npx supabase link --project-ref SEU_PROJECT_REF
   npx supabase secrets set GEMINI_API_KEY=... ANTHROPIC_API_KEY=...
   npx supabase functions deploy compor-cantiga
   ```
   Opcional: `GEMINI_MODEL` e `CLAUDE_MODEL` para trocar o modelo sem mexer no código.

Testar a lógica do backend (precisa de Node 22+):
```bash
cd supabase/functions/compor-cantiga
node --experimental-strip-types nucleo/teste.ts
```

## 2. App (no PC com Flutter)

```powershell
cd cantador\app
flutter create --platforms=android --org br.cantador --project-name cantador .
flutter pub get
flutter test
flutter build apk --release `
  --dart-define=SUPABASE_URL=https://SEU_PROJECT_REF.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=SUA_CHAVE_ANON
```

O `flutter create` só completa os arquivos que faltam da pasta `android/` e mantém o
`AndroidManifest.xml` que já vem com a permissão de internet.
O APK fica em `app\build\app\outputs\flutter-apk\app-release.apk`. Mande para o celular e instale.

A chave *anon* (Supabase → Project Settings → API) é pública por natureza. As chaves das IAs ficam só no servidor.

## 3. Como o app se lapida

| Ação do compositor | O que o app aprende |
| :--- | :--- |
| 👍 numa cantiga | Salva no caderno e passa a mandá-la como referência de gosto (até 3 por forma) |
| 👎 + explicação | A crítica vira preferência ("Evitar: …") em Ajustes → Seu gosto |
| Apagar palavras ao editar | O app oferece colocá-las na lista negra |
| Votos em cada IA | Com 5+ votos em cada, o modo Automático passa a usar a mais aprovada |

## 4. Regras de manutenção

- A regra da lista negra existe em dois lugares: `app/lib/nucleo/lista_negra.dart` e
  `supabase/functions/compor-cantiga/nucleo/listaNegra.ts`. Mude os dois juntos.
- O prompt oficial fica só em `nucleo/prompt.ts`. O app manda apenas os parâmetros.
