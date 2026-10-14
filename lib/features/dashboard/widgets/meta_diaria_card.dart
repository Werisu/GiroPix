import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/metas_diarias.dart';
import '../../../providers/finance_provider.dart';
import '../../metas/metas_diarias_screen.dart';

class MetaDiariaCard extends StatelessWidget {
  const MetaDiariaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final progresso = finance.progressoMetaDiaria();
    final hoje = MetasDiarias.nome(DateTime.now().weekday);

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
                color: AppColors.neonBlue.withValues(alpha: 0.35),
              ),
            ),
            child: progresso.definida
                ? _MetaDoDia(hoje: hoje, progresso: progresso)
                : _SemMetaHoje(
                    temOutras: finance.metasDiarias.temAlguma,
                    hoje: hoje,
                  ),
          ),
        ),
      ),
    );
  }
}

class _SemMetaHoje extends StatelessWidget {
  const _SemMetaHoje({
    required this.temOutras,
    required this.hoje,
  });

  final bool temOutras;
  final String hoje;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Titulo(),
        const SizedBox(height: 12),
        Text(
          temOutras
              ? '$hoje está sem meta de faturamento. Toque para definir ou copiar de outro dia.'
              : 'Defina quanto você quer faturar em cada dia da semana.',
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

class _MetaDoDia extends StatelessWidget {
  const _MetaDoDia({
    required this.hoje,
    required this.progresso,
  });

  final String hoje;
  final ProgressoMetaDiaria progresso;

  @override
  Widget build(BuildContext context) {
    final percentual = (progresso.progresso * 100).round();
    final barra = progresso.progresso > 1 ? 1.0 : progresso.progresso;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Titulo(),
        const SizedBox(height: 12),
        Text(
          hoje,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatBrl(progresso.realizado)} de ${formatBrl(progresso.meta)}',
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
            color: progresso.atingida ? AppColors.neonGreen : AppColors.neonBlue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          progresso.atingida
              ? 'Meta batida · $percentual%'
              : 'Falta ${formatBrl(progresso.falta)} · $percentual%',
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
  const _Titulo();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.flag_rounded, color: AppColors.neonBlue, size: 18),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Meta do dia',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      ],
    );
  }
}
