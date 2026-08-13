import 'package:flutter/material.dart';

import '../../data/models/corrida.dart';
import '../../data/models/gasto.dart';
import 'widgets/corrida_form.dart';
import 'widgets/gasto_form.dart';

class EditarCorridaScreen extends StatelessWidget {
  const EditarCorridaScreen({super.key, required this.corrida});

  final Corrida corrida;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar corrida')),
      body: SafeArea(child: CorridaForm(corrida: corrida)),
    );
  }
}

class EditarGastoScreen extends StatelessWidget {
  const EditarGastoScreen({super.key, required this.gasto});

  final Gasto gasto;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar gasto')),
      body: SafeArea(child: GastoForm(gasto: gasto)),
    );
  }
}
