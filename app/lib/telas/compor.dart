import 'package:flutter/material.dart';

import '../nucleo/catalogo.dart';
import '../servicos/api.dart';
import '../servicos/armazenamento.dart';
import 'campo_de_palavras.dart';
import 'resultado.dart';

class TelaCompor extends StatefulWidget {
  const TelaCompor({super.key, required this.arm});
  final Armazenamento arm;

  @override
  State<TelaCompor> createState() => _TelaComporState();
}

class _TelaComporState extends State<TelaCompor> {
  String _linhagem = 'livre';
  String _forma = 'corrido';
  String _toque = 'sao_bento_grande_regional';
  late String _ia = widget.arm.ia;
  final _tema = TextEditingController();
  List<String> _chave = [];
  late List<String> _proibidas = widget.arm.listaNegra;
  bool _compondo = false;

  @override
  void dispose() {
    _tema.dispose();
    super.dispose();
  }

  PedidoComposicao _pedido() => PedidoComposicao(
        forma: _forma,
        toque: _toque,
        linhagem: _linhagem,
        tema: _tema.text.trim(),
        ia: _ia == 'auto' ? widget.arm.iaEfetiva() : _ia,
        palavrasChave: _chave,
        listaNegra: _proibidas,
        notasDeEstilo: widget.arm.notasDeEstilo,
        exemplos: widget.arm.exemplosAprovados(_forma),
        chaves: widget.arm.chaves,
      );

  Future<void> _compor() async {
    setState(() => _compondo = true);
    final pedido = _pedido();
    try {
      final letra = await Api.compor(pedido);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TelaResultado(arm: widget.arm, letra: letra, pedido: pedido),
      ));
      // A lista negra pode ter crescido no resultado.
      setState(() => _proibidas = widget.arm.listaNegra);
    } on ErroCompor catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
      }
    } finally {
      if (mounted) setState(() => _compondo = false);
    }
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(t, style: Theme.of(context).textTheme.titleSmall),
      );

  Widget _escolhas(List<Opcao> opcoes, String atual, ValueChanged<String> aoEscolher) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final o in opcoes)
            Tooltip(
              message: o.descricao,
              child: ChoiceChip(
                label: Text(o.nome),
                selected: atual == o.chave,
                onSelected: (_) => setState(() => aoEscolher(o.chave)),
              ),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final aviso = avisoDeCombinacao(_forma, _toque);
    final tema = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text('Compor cantiga', style: tema.textTheme.headlineSmall),
        _titulo('Linhagem'),
        _escolhas(linhagens, _linhagem, (v) => _linhagem = v),
        _titulo('Forma do canto'),
        _escolhas(formas, _forma, (v) => _forma = v),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(formas.firstWhere((f) => f.chave == _forma).descricao, style: tema.textTheme.bodySmall),
        ),
        _titulo('Toque'),
        _escolhas(toques, _toque, (v) => _toque = v),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(avisoIuna, style: tema.textTheme.bodySmall),
        ),
        if (aviso != null)
          Card(
            margin: const EdgeInsets.only(top: 12),
            color: tema.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Expanded(child: Text('$aviso Pode compor assim mesmo.')),
              ]),
            ),
          ),
        _titulo('Inteligência artificial'),
        _escolhas(ias, _ia, (v) => _ia = v),
        _titulo('Tema'),
        TextField(
          controller: _tema,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Sobre o que é a cantiga?',
            hintText: 'ex.: jangadeiro enfrentando a maré cheia',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        CampoDePalavras(
          rotulo: 'Palavras que DEVEM entrar',
          dica: 'Digite e toque em +. Pode separar por vírgula.',
          palavras: _chave,
          aoMudar: (l) => setState(() => _chave = l),
        ),
        const SizedBox(height: 16),
        CampoDePalavras(
          rotulo: 'Palavras que NÃO podem entrar',
          dica: 'Fica salvo para as próximas. Plural, diminutivo e sem acento também são bloqueados.',
          palavras: _proibidas,
          corDoChip: tema.colorScheme.errorContainer,
          aoMudar: (l) {
            setState(() => _proibidas = l);
            widget.arm.salvarListaNegra(l);
          },
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _compondo ? null : _compor,
          icon: _compondo
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.music_note),
          label: Text(_compondo ? 'Compondo…' : 'Compor cantiga'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      ],
    );
  }
}
