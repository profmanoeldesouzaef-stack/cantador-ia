import 'package:flutter/material.dart';

import '../nucleo/lista_negra.dart';

/// Campo onde se digita uma palavra (ou várias separadas por vírgula) e ela vira um chip.
class CampoDePalavras extends StatefulWidget {
  const CampoDePalavras({
    super.key,
    required this.rotulo,
    required this.palavras,
    required this.aoMudar,
    this.dica,
    this.corDoChip,
  });

  final String rotulo;
  final String? dica;
  final List<String> palavras;
  final ValueChanged<List<String>> aoMudar;
  final Color? corDoChip;

  @override
  State<CampoDePalavras> createState() => _CampoDePalavrasState();
}

class _CampoDePalavrasState extends State<CampoDePalavras> {
  final _ctrl = TextEditingController();

  void _adicionar() {
    final novas = _ctrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    final lista = List.of(widget.palavras);
    final existentes = lista.map(normalizar).toSet();
    for (final n in novas) {
      if (existentes.add(normalizar(n))) lista.add(n);
    }
    _ctrl.clear();
    widget.aoMudar(lista);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            labelText: widget.rotulo,
            helperText: widget.dica,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: 'Adicionar',
              icon: const Icon(Icons.add),
              onPressed: _adicionar,
            ),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _adicionar(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final p in widget.palavras)
              InputChip(
                label: Text(p),
                backgroundColor: widget.corDoChip,
                onDeleted: () => widget.aoMudar(List.of(widget.palavras)..remove(p)),
                deleteButtonTooltipMessage: 'Remover "$p"',
              ),
          ],
        ),
      ],
    );
  }
}
