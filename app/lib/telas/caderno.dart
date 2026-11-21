import 'package:flutter/material.dart';

import '../modelos.dart';
import '../nucleo/catalogo.dart';
import '../servicos/armazenamento.dart';
import 'resultado.dart';

class TelaCaderno extends StatefulWidget {
  const TelaCaderno({super.key, required this.arm});
  final Armazenamento arm;

  @override
  State<TelaCaderno> createState() => _TelaCadernoState();
}

class _TelaCadernoState extends State<TelaCaderno> {
  late List<Letra> _letras = widget.arm.caderno;

  void _recarregar() => setState(() => _letras = widget.arm.caderno);

  Future<void> _abrir(Letra l) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TelaResultado(arm: widget.arm, letra: l)));
    _recarregar();
  }

  Future<void> _apagar(Letra l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Apagar "${l.titulo}"?'),
        content: const Text('A letra sai do caderno e não dá para recuperar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Manter')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Apagar "${l.titulo}"')),
        ],
      ),
    );
    if (ok == true) {
      await widget.arm.apagarLetra(l.id);
      _recarregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    if (_letras.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.menu_book, size: 48, color: tema.colorScheme.outline),
            const SizedBox(height: 12),
            Text('Caderno vazio', style: tema.textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'Componha uma cantiga e toque em Salvar ou em 👍.\nAs aprovadas ensinam o seu gosto para a IA.',
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _letras.length + 1,
      separatorBuilder: (_, i) => i == 0 ? const SizedBox.shrink() : const Divider(height: 1),
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('Caderno de Músicas', style: tema.textTheme.headlineSmall),
          );
        }
        final l = _letras[i - 1];
        return ListTile(
          leading: Icon(
            l.avaliacao > 0 ? Icons.thumb_up : Icons.music_note,
            color: l.avaliacao > 0 ? tema.colorScheme.primary : null,
          ),
          title: Text(l.titulo),
          subtitle: Text('${nomeDa(formas, l.forma)} · ${nomeDa(toques, l.toque)}'),
          onTap: () => _abrir(l),
          trailing: IconButton(
            tooltip: 'Apagar',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _apagar(l),
          ),
        );
      },
    );
  }
}
