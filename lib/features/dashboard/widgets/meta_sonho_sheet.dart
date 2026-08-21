import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/meta_sonho.dart';
import '../../../providers/finance_provider.dart';

Future<void> showMetaSonhoEditor(
  BuildContext context, {
  MetaSonho? atual,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => MetaSonhoEditorSheet(atual: atual),
  );
}

Future<void> showGuardarNaMeta(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const GuardarNaMetaSheet(),
  );
}

class MetaSonhoEditorSheet extends StatefulWidget {
  const MetaSonhoEditorSheet({super.key, this.atual});

  final MetaSonho? atual;

  @override
  State<MetaSonhoEditorSheet> createState() => _MetaSonhoEditorSheetState();
}

class _MetaSonhoEditorSheetState extends State<MetaSonhoEditorSheet> {
  final _tituloCtrl = TextEditingController();
  final _alvoCtrl = TextEditingController();
  final _guardadoCtrl = TextEditingController();
  late TipoMeta _tipo;
  bool _saving = false;

  bool get _editing => widget.atual != null;

  @override
  void initState() {
    super.initState();
    final atual = widget.atual;
    _tipo = atual?.tipo ?? TipoMeta.moto;
    _tituloCtrl.text = atual?.titulo ?? '';
    if (atual != null) {
      _alvoCtrl.text = formatInputBrl(atual.valorAlvo);
      if (atual.valorGuardado > 0) {
        _guardadoCtrl.text = formatInputBrl(atual.valorGuardado);
      }
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _alvoCtrl.dispose();
    _guardadoCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final titulo = _tituloCtrl.text.trim();
    final alvo = parseBrl(_alvoCtrl.text);
    final guardado = parseBrl(_guardadoCtrl.text) ?? 0;

    if (titulo.isEmpty) {
      _avisar('Dê um nome ao sonho. Ex: moto esportiva.');
      return;
    }
    if (alvo == null || alvo < 1) {
      _avisar('Informe o valor que você quer alcançar.');
      return;
    }
    if (guardado < 0) {
      _avisar('O valor já guardado não pode ser negativo.');
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<FinanceProvider>().salvarMetaSonho(
            MetaSonho(
              titulo: titulo,
              valorAlvo: alvo,
              valorGuardado: guardado,
              tipo: _tipo,
              criadaEm: widget.atual?.criadaEm ?? DateTime.now(),
            ),
          );
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remover() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Remover meta?'),
        content: const Text(
          'O progresso guardado nesta meta será apagado. Os lançamentos de corrida e gasto continuam iguais.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    await context.read<FinanceProvider>().removerMetaSonho();
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _avisar(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
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
                _editing ? 'Editar sonho' : 'Qual é o seu sonho?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Defina o objetivo, o valor e quanto você já juntou.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tipo in TipoMeta.values)
                    ChoiceChip(
                      label: Text(tipo.label),
                      avatar: Icon(tipo.icon, size: 16),
                      selected: _tipo == tipo,
                      onSelected: (_) => setState(() => _tipo = tipo),
                      selectedColor: AppColors.neonGreen.withValues(alpha: 0.22),
                      backgroundColor: AppColors.surfaceLight,
                      labelStyle: TextStyle(
                        color: _tipo == tipo
                            ? AppColors.neonGreen
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: _tipo == tipo
                            ? AppColors.neonGreen
                            : AppColors.border,
                      ),
                      showCheckmark: false,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tituloCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'O que você quer conquistar',
                  hintText: 'Ex: Moto esportiva',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _alvoCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor da meta (R\$)',
                  hintText: 'Ex: 18.000,00',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _guardadoCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Já tenho (R\$)',
                  hintText: '0,00',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _salvar,
                  child: Text(_editing ? 'Salvar alterações' : 'Definir meta'),
                ),
              ),
              if (_editing) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _saving ? null : _remover,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    child: const Text('Remover meta'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class GuardarNaMetaSheet extends StatefulWidget {
  const GuardarNaMetaSheet({super.key});

  @override
  State<GuardarNaMetaSheet> createState() => _GuardarNaMetaSheetState();
}

class _GuardarNaMetaSheetState extends State<GuardarNaMetaSheet> {
  final _valorCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar([double? direto]) async {
    final valor = direto ?? parseBrl(_valorCtrl.text);
    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor para guardar.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<FinanceProvider>().guardarNaMeta(valor);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${formatBrl(valor)} guardados na meta.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final lucroHoje = finance.resumoDoDia(DateTime.now()).lucroLiquidoReal;
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + inset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const Text(
              'Guardar na meta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              finance.metaSonho == null
                  ? 'Defina um sonho para começar a juntar.'
                  : 'Soma este valor ao que você já juntou para ${finance.metaSonho!.titulo}.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valorCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                hintText: 'Ex: 50,00',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final atalho in const [50.0, 100.0, 200.0])
                  ActionChip(
                    label: Text(formatBrl(atalho)),
                    onPressed: _saving ? null : () => _guardar(atalho),
                    backgroundColor: AppColors.surfaceLight,
                    side: const BorderSide(color: AppColors.border),
                    labelStyle: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                if (lucroHoje > 0)
                  ActionChip(
                    label: Text('Lucro de hoje · ${formatBrl(lucroHoje)}'),
                    onPressed: _saving ? null : () => _guardar(lucroHoje),
                    backgroundColor: AppColors.neonGreen.withValues(alpha: 0.12),
                    side: BorderSide(
                      color: AppColors.neonGreen.withValues(alpha: 0.45),
                    ),
                    labelStyle: const TextStyle(
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _guardar,
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
