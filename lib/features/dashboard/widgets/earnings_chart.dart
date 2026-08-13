import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';

class EarningsChart extends StatelessWidget {
  const EarningsChart({super.key, required this.data, required this.periodo});

  final List<({DateTime inicio, double ganhos})> data;
  final PeriodoFiltro periodo;

  bool get _porHora => periodo == PeriodoFiltro.dia;

  String get _titulo => 'Ganhos — ${periodo.label}';

  String get _subtitulo => _porHora
      ? 'Valor líquido das corridas por horário'
      : 'Valor líquido das corridas por dia';

  String _labelEixo(DateTime inicio) {
    if (_porHora) {
      return '${inicio.hour.toString().padLeft(2, '0')}h';
    }
    if (periodo == PeriodoFiltro.semana) {
      final label = DateFormat.E('pt_BR').format(inicio);
      return label.substring(0, 1).toUpperCase() +
          (label.length > 1 ? label.substring(1, 3) : '');
    }
    return '${inicio.day}';
  }

  String _tooltipTitulo(DateTime inicio) {
    if (_porHora) {
      final fimHora = inicio.hour + 3;
      return '${inicio.hour.toString().padLeft(2, '0')}h–'
          '${fimHora.toString().padLeft(2, '0')}h';
    }
    return DateFormat("dd/MM", 'pt_BR').format(inicio);
  }

  @override
  Widget build(BuildContext context) {
    final maxY = data.fold<double>(0, (m, e) => e.ganhos > m ? e.ganhos : m);
    final chartMax = maxY <= 0 ? 100.0 : maxY * 1.25;
    final barWidth = data.length <= 8
        ? 14.0
        : data.length <= 16
        ? 8.0
        : 5.0;
    final labelStep = data.length > 16
        ? 3
        : data.length > 10
        ? 2
        : 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text(
              _titulo,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Text(
              _subtitulo,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: data.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum dia neste período',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: chartMax,
                      minY: 0,
                      groupsSpace: data.length > 16 ? 2 : 4,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: chartMax / 4,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.border.withValues(alpha: 0.6),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: chartMax / 2,
                            getTitlesWidget: (value, meta) {
                              if (value == 0 || value == meta.max) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(
                                    value >= 1000
                                        ? '${(value / 1000).toStringAsFixed(1)}k'
                                        : value.toInt().toString(),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= data.length) {
                                return const SizedBox.shrink();
                              }
                              final isEdge =
                                  index == 0 || index == data.length - 1;
                              if (labelStep > 1 &&
                                  index % labelStep != 0 &&
                                  !isEdge) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _labelEixo(data[index].inicio),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(data.length, (i) {
                        final value = data[i].ganhos;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: value <= 0 ? 0.5 : value,
                              width: barWidth,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              gradient: LinearGradient(
                                colors: value <= 0
                                    ? [AppColors.border, AppColors.border]
                                    : [AppColors.neonBlue, AppColors.neonGreen],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ],
                        );
                      }),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.surfaceLight,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final item = data[group.x];
                            return BarTooltipItem(
                              '${_tooltipTitulo(item.inicio)}\n${formatBrl(item.ganhos)}',
                              const TextStyle(
                                color: AppColors.neonGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
