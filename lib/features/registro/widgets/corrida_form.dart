import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/finance_provider.dart';
import 'payment_selector.dart';

class CorridaForm extends StatefulWidget {
  const CorridaForm({super.key});

  @override
  State<CorridaForm> createState() => _CorridaFormState();
}

class _CorridaFormState extends State<CorridaForm> {
  final _formKey = GlobalKey<FormState>();
  final _valorBrutoCtrl = TextEditingController();
  final _taxaCtrl = TextEditingController();
  final _taxaPercentCtrl = TextEditingController();

  String _formaPagamento = 'Pix';
  bool _usarPercentual = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _valorBrutoCtrl.addListener(_recalcularTaxa);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final taxa = context.read<FinanceProvider>().taxaPadraoPercent;
      _taxaPercentCtrl.text = taxa.toStringAsFixed(
        taxa.truncateToDouble() == taxa ? 0 : 1,
      );
      setState(() {});
    });
  }

  @override
  void dispose() {
    _valorBrutoCtrl.removeListener(_recalcularTaxa);
    _valorBrutoCtrl.dispose();
    _taxaCtrl.dispose();
    _taxaPercentCtrl.dispose();
    super.dispose();
  }

  void _recalcularTaxa() {
    if (!_usarPercentual) return;
    final bruto = parseBrl(_valorBrutoCtrl.text);
    final percent = parseBrl(_taxaPercentCtrl.text);
    if (bruto == null || percent == null) {
      _taxaCtrl.text = '';
      return;
    }
    final taxa = bruto * (percent / 100);
    _taxaCtrl.text = taxa.toStringAsFixed(2).replaceAll('.', ',');
    setState(() {});
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final bruto = parseBrl(_valorBrutoCtrl.text)!;
    final taxa = parseBrl(_taxaCtrl.text) ?? 0;

    if (taxa > bruto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A taxa não pode ser maior que o valor bruto.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final finance = context.read<FinanceProvider>();
      if (_usarPercentual) {
        final percent = parseBrl(_taxaPercentCtrl.text);
        if (percent != null) {
          await finance.setTaxaPadraoPercent(percent);
        }
      }
      await finance.adicionarCorrida(
        valorBruto: bruto,
        taxaApp: taxa,
        formaPagamento: _formaPagamento,
      );

      if (!mounted) return;
      _valorBrutoCtrl.clear();
      _taxaCtrl.clear();
      _recalcularTaxa();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Corrida salva! Líquido: ${formatBrl(bruto - taxa)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bruto = parseBrl(_valorBrutoCtrl.text) ?? 0;
    final taxa = parseBrl(_taxaCtrl.text) ?? 0;
    final liquido = bruto - taxa;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text(
            'Nova corrida',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Lance rápido — valor, taxa e pagamento',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _valorBrutoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.neonGreen,
            ),
            decoration: const InputDecoration(
              labelText: 'Valor Bruto',
              prefixText: 'R\$ ',
              prefixStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            validator: (v) {
              final value = parseBrl(v ?? '');
              if (value == null || value <= 0) {
                return 'Informe um valor válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Taxa do App',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                _usarPercentual ? '% padrão' : 'Valor fixo',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Switch(
                value: _usarPercentual,
                activeThumbColor: AppColors.neonGreen,
                onChanged: (v) {
                  setState(() {
                    _usarPercentual = v;
                    if (v) _recalcularTaxa();
                  });
                },
              ),
            ],
          ),
          if (_usarPercentual) ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _taxaPercentCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    onChanged: (_) => _recalcularTaxa(),
                    decoration: const InputDecoration(
                      labelText: 'Percentual padrão',
                      suffixText: '%',
                    ),
                    validator: (v) {
                      final value = parseBrl(v ?? '');
                      if (value == null || value < 0 || value > 100) {
                        return '0 a 100';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _taxaCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Taxa calculada',
                      prefixText: 'R\$ ',
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            TextFormField(
              controller: _taxaCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Taxa do App (R\$)',
                prefixText: 'R\$ ',
              ),
              validator: (v) {
                final value = parseBrl(v ?? '');
                if (value == null || value < 0) {
                  return 'Informe a taxa';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Forma de pagamento',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 12),
          PaymentSelector(
            selected: _formaPagamento,
            onChanged: (v) => setState(() => _formaPagamento = v),
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
                  'Valor líquido',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  formatBrl(liquido < 0 ? 0 : liquido),
                  style: const TextStyle(
                    color: AppColors.neonGreen,
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
              onPressed: _saving ? null : _salvar,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(_saving ? 'Salvando...' : 'Salvar corrida'),
            ),
          ),
        ],
      ),
    );
  }
}
