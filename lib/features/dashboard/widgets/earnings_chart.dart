import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/utils/fantasma_dia.dart';

class EarningsChart extends StatelessWidget {
  const EarningsChart({
    super.key,
    required this.data,
    required this.periodo,
    this.fantasma,
  });

  final List<({DateTime inicio, double ganhos})> data;
  final PeriodoFiltro periodo;
  final FantasmaDia? fantasma;

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
    final maxY = [
      for (final item in data) item.ganhos,
      if (fantasma != null) ...fantasma!.ganhosPorFaixa,
    ].fold<double>(0, (maior, valor) => valor > maior ? valor : maior);
    final chartMax = maxY <= 0 ? 100.0 : maxY * 1.25;
    final mostraFantasma =
        _porHora &&
        fantasma != null &&
        fantasma!.ganhosPorFaixa.length == data.length;
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
          if (mostraFantasma) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: _FraseFantasma(fantasma: fantasma!),
            ),
          ],
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
                : Stack(
                    children: [
                      BarChart(
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
                                        : [context.accentAlt, context.accent],
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
                                  TextStyle(
                                    color: context.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      if (mostraFantasma)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _LinhaFantasmaPainter(
                                valores: fantasma!.ganhosPorFaixa,
                                maxY: chartMax,
                                barWidth: barWidth,
                                indiceAgora: fantasma!.faixaAtual,
                                cor: _corFantasma(context, fantasma!),
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

Color _corFantasma(BuildContext context, FantasmaDia fantasma) {
  if (fantasma.naFrente) return context.accent;
  if (fantasma.atras) return const Color(0xFF6EA8FF);
  return AppColors.textSecondary;
}

class _FraseFantasma extends StatelessWidget {
  const _FraseFantasma({required this.fantasma});

  final FantasmaDia fantasma;

  @override
  Widget build(BuildContext context) {
    final cor = _corFantasma(context, fantasma);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 16,
            height: 3,
            decoration: BoxDecoration(
              color: cor,
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(color: cor.withValues(alpha: 0.7), blurRadius: 6),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            fraseFantasma(fantasma),
            style: TextStyle(
              color: cor,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Linha do fantasma no mesmo eixo das barras (alinhamento spaceEvenly).
class _LinhaFantasmaPainter extends CustomPainter {
  _LinhaFantasmaPainter({
    required this.valores,
    required this.maxY,
    required this.barWidth,
    required this.indiceAgora,
    required this.cor,
  });

  final List<double> valores;
  final double maxY;
  final double barWidth;
  final int indiceAgora;
  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    if (valores.isEmpty || maxY <= 0) return;
    final pontos = _centros(size);
    final corte = indiceAgora.clamp(0, pontos.length - 1);
    final solido = pontos.sublist(0, corte + 1);
    final resto = pontos.sublist(corte);

    _traco(canvas, solido, cor.withValues(alpha: 0.4), 6, 3.5);
    _traco(canvas, solido, cor, 2.4, 0);
    _traco(canvas, resto, cor.withValues(alpha: 0.35), 2, 0);

    for (var i = 0; i < pontos.length; i++) {
      final atual = i == corte;
      final tinta = i <= corte ? cor : cor.withValues(alpha: 0.4);
      if (atual) {
        canvas.drawCircle(
          pontos[i],
          8,
          Paint()
            ..color = cor.withValues(alpha: 0.28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      canvas.drawCircle(pontos[i], atual ? 4.2 : 2.2, Paint()..color = tinta);
    }
  }

  List<Offset> _centros(Size size) {
    final n = valores.length;
    final eachSpace = (size.width - (barWidth * n)) / (n + 1);
    final pontos = <Offset>[];
    var x = 0.0;
    for (var i = 0; i < n; i++) {
      x += eachSpace;
      final centro = x + (barWidth / 2);
      x += barWidth;
      final valor = valores[i] > 0 ? valores[i] : 0.0;
      final y = size.height - (valor / maxY) * size.height;
      pontos.add(Offset(centro, y));
    }
    return pontos;
  }

  void _traco(
    Canvas canvas,
    List<Offset> pontos,
    Color cor,
    double espessura,
    double desfoque,
  ) {
    if (pontos.length < 2) return;
    final path = Path()..moveTo(pontos.first.dx, pontos.first.dy);
    for (final ponto in pontos.skip(1)) {
      path.lineTo(ponto.dx, ponto.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessura
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = desfoque > 0
            ? MaskFilter.blur(BlurStyle.normal, desfoque)
            : null,
    );
  }

  bool _valoresDiferentes(List<double> outros) {
    for (var i = 0; i < valores.length; i++) {
      if (valores[i] != outros[i]) return true;
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant _LinhaFantasmaPainter oldDelegate) {
    return oldDelegate.maxY != maxY ||
        oldDelegate.cor != cor ||
        oldDelegate.barWidth != barWidth ||
        oldDelegate.indiceAgora != indiceAgora ||
        oldDelegate.valores.length != valores.length ||
        _valoresDiferentes(oldDelegate.valores);
  }
}
