import 'package:flutter/material.dart';

import 'servicos/armazenamento.dart';
import 'telas/ajustes.dart';
import 'telas/caderno.dart';
import 'telas/compor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final arm = await Armazenamento.abrir();
  runApp(CantadorApp(arm: arm));
}

class CantadorApp extends StatelessWidget {
  const CantadorApp({super.key, required this.arm});
  final Armazenamento arm;

  @override
  Widget build(BuildContext context) {
    final esquema = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7A4A1E), // madeira de biriba
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'Cantador IA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: esquema, useMaterial3: true),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7A4A1E), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: Inicio(arm: arm),
    );
  }
}

class Inicio extends StatefulWidget {
  const Inicio({super.key, required this.arm});
  final Armazenamento arm;

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  int _aba = 0;
  // Muda a chave para recarregar o caderno quando a aba é aberta.
  int _versaoCaderno = 0;

  @override
  Widget build(BuildContext context) {
    final telas = [
      TelaCompor(arm: widget.arm),
      TelaCaderno(key: ValueKey(_versaoCaderno), arm: widget.arm),
      TelaAjustes(arm: widget.arm),
    ];
    return Scaffold(
      body: SafeArea(child: telas[_aba]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (i) => setState(() {
          _aba = i;
          if (i == 1) _versaoCaderno++;
        }),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.edit_note), label: 'Compor'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Caderno'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Ajustes'),
        ],
      ),
    );
  }
}
