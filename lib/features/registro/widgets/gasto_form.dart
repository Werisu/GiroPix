import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/datetime_field.dart';
import '../../../data/models/gasto.dart';
import '../../../providers/finance_provider.dart';

class GastoForm extends StatefulWidget {
  const GastoForm({super.key, this.gasto});

  final Gasto? gasto;

  @override
  State<GastoForm> createState() => _GastoFormState();
}

class _GastoFormState extends State<GastoForm> {
  final _formKey = GlobalKey<FormState>();
  final _combustivelCtrl = TextEditingController();
  final _alimentacaoCtrl = TextEditingController();
  final _outrosCtrl = TextEditingController();
  late DateTime _dataHora;
  bool _saving = false;

  bool get _editing => widget.gasto != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.gasto;
    _dataHora = existing?.data ?? DateTime.now();
    if (existing != null) {
      if (existing.combustivel > 0) {
        _combustivelCtrl.text = formatInputBrl(existing.combustivel);
      }
      if (existing.alimentacao > 0) {
        _alimentacaoCtrl.text = formatInputBrl(existing.alimentacao);
      }
      if (existing.outros > 0) {
        _outrosCtrl.text = formatInputBrl(existing.outros);
      }
    }
  }

  @override
  void dispose() {
    _combustivelCtrl.dispose();
    _alimentacaoCtrl.dispose();
    _outrosCtrl.dispose();
    super.dispose();
  }

  double get _total {
    final c = parseBrl(_combustivelCtrl.text) ?? 0;
    final a = parseBrl(_alimentacaoCtrl.text) ?? 0;
    final o = parseBrl(_outrosCtrl.text) ?? 0;
    return c + a + o;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final combustivel = parseBrl(_combustivelCtrl.text) ?? 0;
    final alimentacao = parseBrl(_alimentacaoCtrl.text) ?? 0;
    final outros = parseBrl(_outrosCtrl.text) ?? 0;

    if (combustivel + alimentacao + outros <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe ao menos um valor de gasto.')),
      );
      return;
    }

    final total = combustivel + alimentacao + outros;

    setState(() => _saving = true);
    try {
      final finance = context.read<FinanceProvider>();
      if (_editing) {
        await finance.atualizarGasto(
          widget.gasto!.copyWith(
            data: _dataHora,
            combustivel: combustivel,
            alimentacao: alimentacao,
            outros: outros,
          ),
        );
      } else {
        await finance.adicionarGasto(
          combustivel: combustivel,
          alimentacao: alimentacao,
          outros: outros,
          data: _dataHora,
        );
      }

      await AppFeedback.lancamentoSalvo();

      if (!mounted) return;
      if (_editing) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Gasto atualizado.')),
        );
        return;
      }

      _combustivelCtrl.clear();
      _alimentacaoCtrl.clear();
      _outrosCtrl.clear();
      _dataHora = DateTime.now();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gastos salvos! Total: ${formatBrl(total)}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color accent,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'R\$ ',
        prefixIcon: Icon(icon, color: accent),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        final value = parseBrl(v);
        if (value == null || value < 0) return 'Valor inválido';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (!_editing) ...[
            const Text(
              'Gastos do dia',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Combustível, alimentação e outros custos',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
          ] else
            const SizedBox(height: 8),
          DateTimeField(
            value: _dataHora,
            onChanged: (v) => setState(() => _dataHora = v),
          ),
          const SizedBox(height: 20),
          _campo(
            controller: _combustivelCtrl,
            label: 'Combustível',
            icon: Icons.local_gas_station_rounded,
            accent: AppColors.warning,
          ),
          const SizedBox(height: 14),
          _campo(
            controller: _alimentacaoCtrl,
            label: 'Alimentação',
            icon: Icons.restaurant_rounded,
            accent: AppColors.neonBlue,
          ),
          const SizedBox(height: 14),
          _campo(
            controller: _outrosCtrl,
            label: 'Outros',
            icon: Icons.more_horiz_rounded,
            accent: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total de gastos',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  formatBrl(_total),
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonBlue,
                foregroundColor: const Color(0xFF001820),
              ),
              onPressed: _saving ? null : _salvar,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _saving
                    ? 'Salvando...'
                    : _editing
                    ? 'Salvar alterações'
                    : 'Salvar gastos',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
