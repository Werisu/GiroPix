import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/models/corrida.dart';
import '../../../data/models/gasto.dart';
import '../../../data/models/resumo_financeiro.dart';
import '../../../providers/finance_provider.dart';

const _weekdays = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

class WorkedDaysCalendar extends StatefulWidget {
  const WorkedDaysCalendar({super.key});

  @override
  State<WorkedDaysCalendar> createState() => _WorkedDaysCalendarState();
}

class _WorkedDaysCalendarState extends State<WorkedDaysCalendar> {
  late DateTime _mes;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _mes = DateTime(now.year, now.month);
  }

  bool get _podeAvancar {
    final agora = DateTime.now();
    return _mes.year < agora.year ||
        (_mes.year == agora.year && _mes.month < agora.month);
  }

  void _mesAnterior() {
    setState(() => _mes = DateTime(_mes.year, _mes.month - 1));
  }

  void _mesSeguinte() {
    if (!_podeAvancar) return;
    setState(() => _mes = DateTime(_mes.year, _mes.month + 1));
  }

  String get _tituloMes {
    final raw = DateFormat('MMMM yyyy', 'pt_BR').format(_mes);
    return '${raw[0].toUpperCase()}${raw.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final trabalhados = finance.diasTrabalhadosNoMes(_mes);
    final hoje = inicioDoDia(DateTime.now());
    final primeiro = inicioDoMes(_mes);
    final diasNoMes = DateTime(_mes.year, _mes.month + 1, 0).day;
    final leading = offsetCalendarioDomingo(primeiro);
    final totalCelulas = ((leading + diasNoMes + 6) ~/ 7) * 7;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dias trabalhados',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Toque no dia para ver o resumo',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Mês anterior',
                  onPressed: _mesAnterior,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  tooltip: 'Próximo mês',
                  onPressed: _podeAvancar ? _mesSeguinte : null,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: _podeAvancar
                        ? AppColors.textPrimary
                        : AppColors.border,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Text(
              _tituloMes,
              style: const TextStyle(
                color: AppColors.neonBlue,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Row(
            children: [
              for (final label in _weekdays)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCelulas,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final diaNum = index - leading + 1;
              if (diaNum < 1 || diaNum > diasNoMes) {
                return const SizedBox.shrink();
              }
              final data = DateTime(_mes.year, _mes.month, diaNum);
              final trabalhou = trabalhados.contains(data);
              final ehHoje = data == hoje;
              return _DayCell(
                day: diaNum,
                worked: trabalhou,
                isToday: ehHoje,
                onTap: () => _abrirResumoDoDia(context, finance, data),
              );
            },
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.neonGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  trabalhados.isEmpty
                      ? 'Nenhum dia trabalhado neste mês'
                      : '${trabalhados.length} dia${trabalhados.length == 1 ? '' : 's'} '
                          'trabalhado${trabalhados.length == 1 ? '' : 's'} neste mês',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirResumoDoDia(
    BuildContext context,
    FinanceProvider finance,
    DateTime dia,
  ) {
    final resumo = finance.resumoDoDia(dia);
    final corridas = finance.corridasDoDia(dia);
    final gastos = finance.gastosDoDia(dia);

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DaySummarySheet(
        dia: dia,
        resumo: resumo,
        corridas: corridas,
        gastos: gastos,
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.worked,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final bool worked;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: worked
                ? AppColors.neonGreen.withValues(alpha: 0.18)
                : Colors.transparent,
            border: isToday
                ? Border.all(color: AppColors.neonBlue, width: 1.5)
                : worked
                    ? Border.all(
                        color: AppColors.neonGreen.withValues(alpha: 0.5),
                      )
                    : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 13,
              fontWeight: worked || isToday
                  ? FontWeight.w800
                  : FontWeight.w500,
              color: worked
                  ? AppColors.neonGreen
                  : isToday
                      ? AppColors.neonBlue
                      : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _DaySummarySheet extends StatelessWidget {
  const _DaySummarySheet({
    required this.dia,
    required this.resumo,
    required this.corridas,
    required this.gastos,
  });

  final DateTime dia;
  final ResumoFinanceiro resumo;
  final List<Corrida> corridas;
  final List<Gasto> gastos;

  @override
  Widget build(BuildContext context) {
    final titulo = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(dia);
    final tituloCap = '${titulo[0].toUpperCase()}${titulo.substring(1)}';
    final vazio = corridas.isEmpty && gastos.isEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tituloCap,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (vazio)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Nenhuma corrida nem gasto neste dia.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Corridas',
                      value: '${resumo.quantidadeCorridas}',
                      color: AppColors.neonBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStat(
                      label: 'Líquido',
                      value: formatBrl(resumo.totalLiquidoCorridas),
                      color: AppColors.neonGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStat(
                      label: 'Lucro',
                      value: formatBrl(resumo.lucroLiquidoReal),
                      color: resumo.lucroLiquidoReal >= 0
                          ? AppColors.profit
                          : AppColors.danger,
                    ),
                  ),
                ],
              ),
              if (gastos.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Gastos: ${formatBrl(resumo.totalGastos)}',
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (corridas.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Corridas',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                for (final c in corridas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('HH:mm').format(c.dataHora),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${c.plataforma == 'Uber' ? 'Maxim' : c.plataforma} · ${c.formaPagamento}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          formatBrl(c.valorLiquido),
                          style: const TextStyle(
                            color: AppColors.neonGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
