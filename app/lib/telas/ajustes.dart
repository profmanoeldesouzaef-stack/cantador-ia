import 'package:flutter/material.dart';

import '../nucleo/catalogo.dart';
import '../nucleo/lista_negra.dart';
import '../servicos/armazenamento.dart';
import 'campo_de_palavras.dart';

class TelaAjustes extends StatefulWidget {
  const TelaAjustes({super.key, required this.arm});
  final Armazenamento arm;

  @override
  State<TelaAjustes> createState() => _TelaAjustesState();
}

class _TelaAjustesState extends State<TelaAjustes> {
  late List<String> _lista = widget.arm.listaNegra;
  late String _ia = widget.arm.ia;
  late final _notas = TextEditingController(text: widget.arm.notasDeEstilo);
  late final _gemini = TextEditingController(text: widget.arm.chaveGemini);
  late final _claude = TextEditingController(text: widget.arm.chaveClaude);
  bool _mostrarChaves = false;

  @override
  void dispose() {
    _notas.dispose();
    _gemini.dispose();
    _claude.dispose();
    super.dispose();
  }

  String _placar(String ia) {
    final pos = widget.arm.votos(ia, 1), neg = widget.arm.votos(ia, -1);
    return '👍 $pos  👎 $neg';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text('Ajustes', style: tema.textTheme.headlineSmall),
        const SizedBox(height: 20),
        Text('Chaves das IAs', style: tema.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Ficam guardadas só neste celular. Gemini: grátis em aistudio.google.com/apikey. '
          'Claude: paga, em console.anthropic.com.',
          style: tema.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _gemini,
          obscureText: !_mostrarChaves,
          decoration: const InputDecoration(labelText: 'Chave do Gemini', border: OutlineInputBorder()),
          onChanged: widget.arm.salvarChaveGemini,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _claude,
          obscureText: !_mostrarChaves,
          decoration: const InputDecoration(labelText: 'Chave do Claude (opcional)', border: OutlineInputBorder()),
          onChanged: widget.arm.salvarChaveClaude,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: Icon(_mostrarChaves ? Icons.visibility_off : Icons.visibility),
            label: Text(_mostrarChaves ? 'Esconder chaves' : 'Mostrar chaves'),
            onPressed: () => setState(() => _mostrarChaves = !_mostrarChaves),
          ),
        ),
        const SizedBox(height: 20),
        Text('Lista negra', style: tema.textTheme.titleSmall),
        const SizedBox(height: 8),
        CampoDePalavras(
          rotulo: 'Adicionar palavra proibida',
          dica: 'Vale para todas as cantigas. Plural, diminutivo e sem acento também são bloqueados.',
          palavras: _lista,
          corDoChip: tema.colorScheme.errorContainer,
          aoMudar: (l) {
            setState(() => _lista = l);
            widget.arm.salvarListaNegra(l);
          },
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.restore),
            label: const Text('Garantir as palavras padrão'),
            onPressed: () async {
              await widget.arm.adicionarProibidas(listaNegraPadrao);
              setState(() => _lista = widget.arm.listaNegra);
            },
          ),
        ),
        const SizedBox(height: 24),
        Text('Seu gosto (a IA lê antes de compor)', style: tema.textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          controller: _notas,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'ex.: prefiro rimas em -ar; coro de no máximo 4 palavras; falar do mar da Bahia',
            helperText: 'Quando você dá 👎 e explica, a crítica entra aqui. Pode editar à vontade.',
            helperMaxLines: 2,
          ),
          onChanged: widget.arm.salvarNotas,
        ),
        const SizedBox(height: 24),
        Text('Inteligência artificial padrão', style: tema.textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final o in ias)
          RadioListTile<String>(
            value: o.chave,
            groupValue: _ia,
            title: Text(o.nome),
            subtitle: Text(o.chave == 'auto' ? o.descricao : '${o.descricao}  ${_placar(o.chave)}'),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _ia = v);
              widget.arm.salvarIa(v);
            },
          ),
        const SizedBox(height: 24),
        Text('Sobre os toques', style: tema.textTheme.titleSmall),
        const SizedBox(height: 4),
        const Text(
          'Iúna fica de fora porque é toque instrumental, sem canto. '
          'As combinações fora da tradição (como ladainha em São Bento Grande da Regional) '
          'são permitidas, com um aviso.',
        ),
      ],
    );
  }
}
