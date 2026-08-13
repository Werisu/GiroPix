import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/datetime_field.dart';
import '../../../data/models/corrida.dart';
import '../../../providers/finance_provider.dart';
import 'payment_selector.dart';
import 'platform_selector.dart';

class CorridaForm extends StatefulWidget {
  const CorridaForm({super.key, this.corrida});

  final Corrida? corrida;

  @override
  State<CorridaForm> createState() => _CorridaFormState();
}

class _CorridaFormState extends State<CorridaForm> {
  final _formKey = GlobalKey<FormState>();
  final _valorBrutoCtrl = TextEditingController();
  final _taxaCtrl = TextEditingController();
  final _taxaPercentCtrl = TextEditingController();

  late DateTime _dataHora;
  String _formaPagamento = 'Pix';
  String _plataforma = '99';
  bool _usarPercentual = true;
  bool _saving = false;

  bool get _editing => widget.corrida != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.corrida;
    _dataHora = existing?.dataHora ?? DateTime.now();

    if (existing != null) {
      _valorBrutoCtrl.text = formatInputBrl(existing.valorBruto);
      _taxaCtrl.text = formatInputBrl(existing.taxaApp);
      _formaPagamento = existing.formaPagamento;
      _plataforma = existing.plataforma;
      if (existing.valorBruto > 0) {
        final percent = (existing.taxaApp / existing.valorBruto) * 100;
        _taxaPercentCtrl.text = percent.toStringAsFixed(
          percent.truncateToDouble() == percent ? 0 : 1,
        );
      }
    }

    _valorBrutoCtrl.addListener(_recalcularTaxa);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || existing != null) return;
      final finance = context.read<FinanceProvider>();
      final taxa = finance.taxaPadraoPercent;
      _taxaPercentCtrl.text = taxa.toStringAsFixed(
        taxa.truncateToDouble() == taxa ? 0 : 1,
      );
      setState(() => _plataforma = finance.plataformaPadrao);
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
        const SnackBar(
          content: Text('A taxa não pode ser maior que o valor bruto.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final finance = context.read<FinanceProvider>();
      if (!_editing && _usarPercentual) {
        final percent = parseBrl(_taxaPercentCtrl.text);
        if (percent != null) {
          await finance.setTaxaPadraoPercent(percent);
        }
      }

      if (_editing) {
        await finance.atualizarCorrida(
          widget.corrida!.copyWith(
            dataHora: _dataHora,
            valorBruto: bruto,
            formaPagamento: _formaPagamento,
            taxaApp: taxa,
            plataforma: _plataforma,
          ),
        );
      } else {
        await finance.adicionarCorrida(
          valorBruto: bruto,
          taxaApp: taxa,
          formaPagamento: _formaPagamento,
          plataforma: _plataforma,
          dataHora: _dataHora,
        );
        await finance.setPlataformaPadrao(_plataforma);
      }

      await AppFeedback.lancamentoSalvo();

      if (!mounted) return;
      if (_editing) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Corrida atualizada.')),
        );
        return;
      }

      _valorBrutoCtrl.clear();
      _taxaCtrl.clear();
      _dataHora = DateTime.now();
      _recalcularTaxa();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Corrida salva! Líquido: ${formatBrl(bruto - taxa)}'),
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
          if (!_editing) ...[
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
              'Lance rápido — valor, app, taxa e pagamento',
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
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
            'App da corrida',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 12),
          PlatformSelector(
            selected: _plataforma,
            onChanged: (v) => setState(() => _plataforma = v),
          ),
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
                  : Icon(
                      _editing
                          ? Icons.save_rounded
                          : Icons.check_circle_outline_rounded,
                    ),
              label: Text(
                _saving
                    ? 'Salvando...'
                    : _editing
                    ? 'Salvar alterações'
                    : 'Salvar corrida',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
