import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/metas_diarias.dart';
import '../../providers/finance_provider.dart';

class MetasDiariasScreen extends StatefulWidget {
  const MetasDiariasScreen({super.key});

  @override
  State<MetasDiariasScreen> createState() => _MetasDiariasScreenState();
}

class _MetasDiariasScreenState extends State<MetasDiariasScreen> {
  final Map<int, TextEditingController> _controllers = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final metas = context.read<FinanceProvider>().metasDiarias;
    for (final dia in MetasDiarias.semana) {
      final valor = metas.metaDe(dia);
      _controllers[dia] = TextEditingController(
        text: valor > 0 ? formatInputBrl(valor) : '',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    final lidas = _lerCampos();
    if (lidas == null) return;

    setState(() => _saving = true);
    try {
      await context.read<FinanceProvider>().salvarMetasDiarias(lidas);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metas diárias salvas.')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  MetasDiarias? _lerCampos() {
    var metas = const MetasDiarias();
    for (final dia in MetasDiarias.semana) {
      final texto = _controllers[dia]!.text.trim();
      if (texto.isEmpty) {
        metas = metas.definir(dia, 0);
        continue;
      }
      final valor = parseBrl(texto);
      if (valor == null || valor < 0) {
        _avisar('Informe um valor válido em ${MetasDiarias.nome(dia)}.');
        return null;
      }
      metas = metas.definir(dia, valor);
    }
    return metas;
  }

  Future<void> _copiar(int origem) async {
    final texto = _controllers[origem]!.text.trim();
    double valor = 0;
    if (texto.isNotEmpty) {
      final lido = parseBrl(texto);
      if (lido == null || lido < 0) {
        _avisar(
          'Informe um valor válido em ${MetasDiarias.nome(origem)} antes de copiar.',
        );
        return;
      }
      valor = lido;
    }

    final destinos = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CopiarMetaSheet(origem: origem, valor: valor),
    );
    if (destinos == null || destinos.isEmpty || !mounted) return;

    final textoDestino = valor <= 0 ? '' : formatInputBrl(valor);
    setState(() {
      for (final dia in destinos) {
        if (dia == origem) continue;
        _controllers[dia]!.text = textoDestino;
      }
    });

    final quantidade = destinos.where((dia) => dia != origem).length;
    _avisar(
      quantidade == 1
          ? 'Meta copiada para 1 dia. Toque em Salvar para gravar.'
          : 'Meta copiada para $quantidade dias. Toque em Salvar para gravar.',
    );
  }

  void _avisar(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas diárias'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: ElevatedButton(
            onPressed: _saving ? null : _salvar,
            child: Text(_saving ? 'Salvando…' : 'Salvar metas'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Text(
            'Faturamento bruto que você quer fazer em cada dia. '
            'Copiar uma meta não altera corridas nem gastos já lançados.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          for (final dia in MetasDiarias.semana) ...[
            _DiaMetaCard(
              dia: dia,
              controller: _controllers[dia]!,
              onCopiar: _saving ? null : () => _copiar(dia),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _DiaMetaCard extends StatelessWidget {
  const _DiaMetaCard({
    required this.dia,
    required this.controller,
    required this.onCopiar,
  });

  final int dia;
  final TextEditingController controller;
  final VoidCallback? onCopiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  MetasDiarias.nome(dia),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                key: ValueKey('copiar-dia-$dia'),
                onPressed: onCopiar,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copiar'),
              ),
            ],
          ),
          TextField(
            key: ValueKey('meta-dia-$dia'),
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Faturamento bruto',
              hintText: '0,00',
              prefixText: 'R\$ ',
            ),
          ),
        ],
      ),
    );
  }
}

class _CopiarMetaSheet extends StatefulWidget {
  const _CopiarMetaSheet({
    required this.origem,
    required this.valor,
  });

  final int origem;
  final double valor;

  @override
  State<_CopiarMetaSheet> createState() => _CopiarMetaSheetState();
}

class _CopiarMetaSheetState extends State<_CopiarMetaSheet> {
  final Set<int> _selecionados = {};

  List<int> get _destinos => [
        for (final dia in MetasDiarias.semana)
          if (dia != widget.origem) dia,
      ];

  bool get _todosMarcados =>
      _destinos.every(_selecionados.contains) && _destinos.isNotEmpty;

  void _alternarTodos() {
    setState(() {
      if (_todosMarcados) {
        _selecionados.clear();
      } else {
        _selecionados
          ..clear()
          ..addAll(_destinos);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final nome = MetasDiarias.nome(widget.origem);
    final valorTexto = widget.valor <= 0
        ? 'sem meta'
        : formatBrl(widget.valor);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + inset),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Copiar meta de $nome',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.valor <= 0
                    ? '$nome está sem meta. Os dias marcados também ficam sem meta.'
                    : 'A meta de $valorTexto será aplicada nos dias marcados. Os outros dias ficam como estão.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const ValueKey('copiar-todos'),
                  onPressed: _alternarTodos,
                  child: Text(
                    _todosMarcados
                        ? 'Limpar seleção'
                        : 'Todos os outros dias',
                  ),
                ),
              ),
              for (final dia in _destinos)
                CheckboxListTile(
                  key: ValueKey('destino-dia-$dia'),
                  contentPadding: EdgeInsets.zero,
                  value: _selecionados.contains(dia),
                  activeColor: AppColors.neonGreen,
                  checkColor: const Color(0xFF001A10),
                  title: Text(MetasDiarias.nome(dia)),
                  onChanged: (marcado) {
                    setState(() {
                      if (marcado == true) {
                        _selecionados.add(dia);
                      } else {
                        _selecionados.remove(dia);
                      }
                    });
                  },
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const ValueKey('confirmar-copia'),
                  onPressed: _selecionados.isEmpty
                      ? null
                      : () => Navigator.pop(context, Set<int>.from(_selecionados)),
                  child: const Text('Copiar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
