import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/models/metas_diarias.dart';
import '../../../providers/finance_provider.dart';
import '../../metas/metas_diarias_screen.dart';

class MetaPeriodoCard extends StatelessWidget {
  const MetaPeriodoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final alvo = finance.alvoMeta();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MetasDiariasScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.accent.withValues(alpha: 0.35),
              ),
            ),
            child: alvo.definida
                ? _MetaAtiva(alvo: alvo)
                : _SemMeta(
                    titulo: alvo.titulo,
                    periodo: finance.periodo,
                    temOutras: finance.metasDiarias.temAlguma,
                  ),
          ),
        ),
      ),
    );
  }
}

class _SemMeta extends StatelessWidget {
  const _SemMeta({
    required this.titulo,
    required this.periodo,
    required this.temOutras,
  });

  final String titulo;
  final PeriodoFiltro periodo;
  final bool temOutras;

  @override
  Widget build(BuildContext context) {
    final texto = temOutras
        ? 'Este período não soma nenhuma meta diária. Toque para ajustar os dias.'
        : 'Defina o faturamento de cada dia. A semana e o mês são calculados sozinhos.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Titulo(titulo: titulo),
        const SizedBox(height: 12),
        Text(
          periodo == PeriodoFiltro.dia && temOutras
              ? 'Hoje está sem meta. Toque para definir ou copiar de outro dia.'
              : texto,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _MetaAtiva extends StatelessWidget {
  const _MetaAtiva({required this.alvo});

  final AlvoMeta alvo;

  @override
  Widget build(BuildContext context) {
    final percentual = (alvo.progresso * 100).round();
    final barra = alvo.progresso > 1 ? 1.0 : alvo.progresso;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Titulo(titulo: alvo.titulo),
        const SizedBox(height: 4),
        Text(
          alvo.detalhe,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${formatBrl(alvo.realizado)} de ${formatBrl(alvo.meta)}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: barra,
            minHeight: 8,
            backgroundColor: AppColors.surfaceLight,
            color: alvo.atingida ? context.accent : context.accentAlt,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          alvo.atingida
              ? 'Meta batida · $percentual%'
              : 'Falta ${formatBrl(alvo.falta)} · $percentual%',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.flag_rounded, color: context.accent, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      ],
    );
  }
}
