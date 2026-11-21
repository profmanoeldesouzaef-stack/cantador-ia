import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../modelos.dart';
import '../nucleo/catalogo.dart';
import '../nucleo/lista_negra.dart';
import '../servicos/api.dart';
import '../servicos/armazenamento.dart';

class TelaResultado extends StatefulWidget {
  const TelaResultado({super.key, required this.arm, required this.letra, this.pedido});
  final Armazenamento arm;
  final Letra letra;

  /// Presente quando a letra acabou de ser gerada (permite "Gerar variação").
  final PedidoComposicao? pedido;

  @override
  State<TelaResultado> createState() => _TelaResultadoState();
}

class _TelaResultadoState extends State<TelaResultado> {
  late Letra _letra = widget.letra.copia();
  late String _textoOriginal = _letra.textoSimples(comCabecalho: false);
  bool _editando = false;
  bool _gerando = false;
  final Map<Linha, TextEditingController> _ctrls = {};
  late final TextEditingController _tituloCtrl = TextEditingController(text: _letra.titulo);

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    _tituloCtrl.dispose();
    super.dispose();
  }

  void _aviso(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  // ---------- Edição ----------
  void _comecarEdicao() {
    for (final s in _letra.secoes) {
      for (final l in s.linhas) {
        _ctrls[l] = TextEditingController(text: l.texto);
      }
    }
    _tituloCtrl.text = _letra.titulo;
    setState(() => _editando = true);
  }

  Future<void> _terminarEdicao() async {
    _letra.titulo = _tituloCtrl.text.trim().isEmpty ? _letra.titulo : _tituloCtrl.text.trim();
    for (final s in _letra.secoes) {
      for (final l in s.linhas) {
        final novo = _ctrls[l]?.text.trim() ?? l.texto;
        if (novo != l.texto) {
          l.texto = novo;
          l.silabas = null; // escansão só vale para o texto da IA
          l.foraDoAlvo = false;
        }
      }
      s.linhas.removeWhere((l) => l.texto.isEmpty);
    }
    for (final c in _ctrls.values) {
      c.dispose();
    }
    _ctrls.clear();
    _letra.proibidasEncontradas = encontrarProibidas(_letra.textoParaFiltro, widget.arm.listaNegra);
    setState(() => _editando = false);
    await _oferecerBloqueio();
  }

  /// Lapidação: palavras que o compositor apagou podem virar proibidas.
  Future<void> _oferecerBloqueio() async {
    final removidas = palavrasRemovidas(_textoOriginal, _letra.textoSimples(comCabecalho: false));
    _textoOriginal = _letra.textoSimples(comCabecalho: false);
    if (removidas.isEmpty || !mounted) return;
    final marcadas = <String>{};
    final escolha = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Bloquear palavras que você tirou?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Marque as que nunca devem aparecer nas próximas cantigas.'),
                for (final w in removidas)
                  CheckboxListTile(
                    value: marcadas.contains(w),
                    title: Text(w),
                    onChanged: (v) => set(() => v == true ? marcadas.add(w) : marcadas.remove(w)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Agora não')),
            FilledButton(onPressed: () => Navigator.pop(ctx, marcadas), child: const Text('Bloquear marcadas')),
          ],
        ),
      ),
    );
    if (escolha != null && escolha.isNotEmpty) {
      await widget.arm.adicionarProibidas(escolha);
      if (!mounted) return;
      _aviso('${escolha.length} palavra(s) adicionada(s) à lista negra.');
    }
  }

  // ---------- Avaliação ----------
  Future<void> _avaliar(int sinal) async {
    if (_letra.avaliacao == sinal) return;
    _letra.avaliacao = sinal;
    await widget.arm.registrarVoto(_letra.ia, sinal);
    if (!mounted) return;
    setState(() {});
    if (sinal > 0) {
      await widget.arm.salvarLetra(_letra);
      if (!mounted) return;
      _aviso('Salva no caderno. As próximas cantigas vão seguir esse gosto.');
      return;
    }
    final ctrl = TextEditingController();
    final critica = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('O que não ficou bom?'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'ex.: coro longo demais, rima forçada, muito clichê',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Pular')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Anotar')),
        ],
      ),
    );
    ctrl.dispose();
    if (critica != null && critica.trim().isNotEmpty) {
      await widget.arm.anotarCritica(critica);
      if (!mounted) return;
      _aviso('Anotado. Vale para as próximas cantigas (veja em Ajustes).');
    }
  }

  // ---------- Ações ----------
  Future<void> _variacao() async {
    final p = widget.pedido;
    if (p == null) return;
    setState(() => _gerando = true);
    try {
      final atualizado = PedidoComposicao(
        forma: p.forma,
        toque: p.toque,
        linhagem: p.linhagem,
        tema: p.tema,
        ia: p.ia,
        palavrasChave: p.palavrasChave,
        listaNegra: widget.arm.listaNegra,
        notasDeEstilo: widget.arm.notasDeEstilo,
        exemplos: widget.arm.exemplosAprovados(p.forma),
        chaves: widget.arm.chaves,
      );
      final nova = await Api.compor(atualizado);
      if (!mounted) return;
      setState(() {
        _letra = nova;
        _textoOriginal = nova.textoSimples(comCabecalho: false);
      });
    } on ErroCompor catch (e) {
      if (mounted) _aviso(e.mensagem);
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  Future<void> _salvar() async {
    await widget.arm.salvarLetra(_letra);
    if (mounted) _aviso('Salva no caderno.');
  }

  Future<void> _copiar() async {
    await Clipboard.setData(ClipboardData(text: _letra.textoSimples()));
    if (mounted) _aviso('Letra copiada.');
  }

  // ---------- Interface ----------
  Widget _linha(Linha l) {
    final cs = Theme.of(context).colorScheme;
    final coro = l.voz == 'coro';
    final selo = GestureDetector(
      onTap: _editando ? () => setState(() => l.voz = coro ? 'solo' : 'coro') : null,
      child: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: coro ? cs.tertiaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(coro ? 'Coro' : 'Solo', style: Theme.of(context).textTheme.labelSmall),
      ),
    );
    final silabas = l.silabas == null
        ? const SizedBox(width: 28)
        : SizedBox(
            width: 28,
            child: Text(
              '${l.silabas}',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: l.foraDoAlvo ? cs.error : cs.outline,
                fontWeight: l.foraDoAlvo ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          selo,
          const SizedBox(width: 10),
          Expanded(
            child: _editando
                ? TextField(controller: _ctrls[l], decoration: const InputDecoration(isDense: true))
                : Text(
                    l.texto,
                    style: TextStyle(fontSize: 17, fontStyle: coro ? FontStyle.italic : FontStyle.normal),
                  ),
          ),
          silabas,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final proibidas = _letra.proibidasEncontradas;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editando' : 'Cantiga'),
        actions: [
          if (_editando)
            IconButton(tooltip: 'Concluir edição', icon: const Icon(Icons.check), onPressed: _terminarEdicao)
          else ...[
            IconButton(tooltip: 'Editar', icon: const Icon(Icons.edit), onPressed: _comecarEdicao),
            IconButton(tooltip: 'Copiar', icon: const Icon(Icons.copy), onPressed: _copiar),
            IconButton(
              tooltip: 'Compartilhar (WhatsApp…)',
              icon: const Icon(Icons.share),
              onPressed: () => Share.share(_letra.textoSimples(), subject: _letra.titulo),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          if (_editando)
            TextField(
              controller: _tituloCtrl,
              style: tema.textTheme.headlineSmall,
              decoration: const InputDecoration(labelText: 'Título'),
            )
          else
            Text(_letra.titulo, style: tema.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            '${nomeDa(formas, _letra.forma)} · ${nomeDa(toques, _letra.toque)}'
            '${_letra.ia.isEmpty ? '' : ' · ${_letra.ia == 'claude' ? 'Claude' : 'Gemini'}'}',
            style: tema.textTheme.bodySmall,
          ),
          if (proibidas.isNotEmpty)
            Card(
              margin: const EdgeInsets.only(top: 12),
              color: tema.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Atenção: a IA insistiu em palavra proibida (${proibidas.join(', ')}). '
                  'Edite o verso ou gere uma variação.',
                ),
              ),
            ),
          if (_editando)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Toque em Solo/Coro para trocar a voz. Linha vazia é apagada.', style: tema.textTheme.bodySmall),
            ),
          for (final s in _letra.secoes) ...[
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 6),
              child: Text(
                (nomesSecao[s.tipo] ?? s.tipo).toUpperCase(),
                style: tema.textTheme.labelLarge?.copyWith(color: tema.colorScheme.primary, letterSpacing: 1.2),
              ),
            ),
            for (final l in s.linhas) _linha(l),
          ],
          if (!_editando && _letra.secoes.any((s) => s.linhas.any((l) => l.silabas != null)))
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Número à direita: sílabas poéticas (estimativa). Em vermelho: fora da métrica esperada.',
                style: tema.textTheme.bodySmall,
              ),
            ),
        ],
      ),
      bottomNavigationBar: _editando
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Gostei',
                      isSelected: _letra.avaliacao > 0,
                      icon: const Icon(Icons.thumb_up_alt_outlined),
                      selectedIcon: const Icon(Icons.thumb_up),
                      onPressed: () => _avaliar(1),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      tooltip: 'Não gostei',
                      isSelected: _letra.avaliacao < 0,
                      icon: const Icon(Icons.thumb_down_alt_outlined),
                      selectedIcon: const Icon(Icons.thumb_down),
                      onPressed: () => _avaliar(-1),
                    ),
                    const Spacer(),
                    if (widget.pedido != null)
                      OutlinedButton.icon(
                        onPressed: _gerando ? null : _variacao,
                        icon: _gerando
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.refresh),
                        label: const Text('Variação'),
                      ),
                    const SizedBox(width: 8),
                    FilledButton.icon(onPressed: _salvar, icon: const Icon(Icons.bookmark_add), label: const Text('Salvar')),
                  ],
                ),
              ),
            ),
    );
  }
}
