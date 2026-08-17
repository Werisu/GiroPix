import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/models/passe_livre.dart';
import '../../../providers/finance_provider.dart';

class PasseLivreCard extends StatelessWidget {
  const PasseLivreCard({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final resumo = finance.analisePasseLivreDoPeriodo();
    if (!resumo.temCorridas) return const SizedBox.shrink();

    final isDia = finance.periodo == PeriodoFiltro.dia;
    final analiseDia = isDia && resumo.analisesPorDia.isNotEmpty
        ? resumo.analisesPorDia.first.analise
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.neonBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.confirmation_number_outlined,
                    color: AppColors.neonBlue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Passe livre Maxim',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isDia
                  ? 'Taxa Maxim hoje: ${formatBrl(resumo.totalTaxasMaxim)}'
                  : 'Taxa Maxim no período: ${formatBrl(resumo.totalTaxasMaxim)}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _subtitulo(resumo, isDia),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            if (analiseDia != null) ...[
              const SizedBox(height: 14),
              PasseLivreComparacoes(analise: analiseDia),
            ] else ...[
              const SizedBox(height: 10),
              Text(
                resumo.diasQueCompensariam == 0
                    ? 'Nenhum dia do período teria compensado comprar o passe.'
                    : 'Em ${resumo.diasQueCompensariam} de ${resumo.diasComMaxim} '
                        'dia${resumo.diasComMaxim == 1 ? '' : 's'} o passe teria '
                        'compensado · economia de ${formatBrl(resumo.economiaPotencial)}',
                style: TextStyle(
                  color: resumo.diasQueCompensariam == 0
                      ? AppColors.textSecondary
                      : AppColors.neonGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Toque no calendário para ver cada dia.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _subtitulo(ResumoPasseLivrePeriodo resumo, bool isDia) {
    final corridas =
        '${resumo.quantidadeCorridasMaxim} corrida${resumo.quantidadeCorridasMaxim == 1 ? '' : 's'} Maxim';
    if (isDia) {
      return '$corridas · comparação com os pacotes de 6h, 12h e 24h';
    }
    return '$corridas em ${resumo.diasComMaxim} dia${resumo.diasComMaxim == 1 ? '' : 's'}';
  }
}

class PasseLivreComparacoes extends StatelessWidget {
  const PasseLivreComparacoes({super.key, required this.analise});

  final AnalisePasseLivre analise;

  @override
  Widget build(BuildContext context) {
    final melhor = analise.melhor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < analise.comparacoes.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _PacoteRow(
            comparacao: analise.comparacoes[i],
            destacado: melhor != null &&
                melhor.pacote.horas == analise.comparacoes[i].pacote.horas,
          ),
        ],
        if (melhor != null) ...[
          const SizedBox(height: 12),
          Text(
            'Melhor escolha: ${melhor.pacote.label} · '
            'economia de ${formatBrl(melhor.economia)}',
            style: const TextStyle(
              color: AppColors.neonGreen,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ] else ...[
          const SizedBox(height: 12),
          const Text(
            'Neste dia o passe não teria compensado: a taxa paga ficou abaixo do preço dos pacotes.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          'Usa as taxas lançadas. Se o passe já estava ativo, a comparação perde o sentido.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _PacoteRow extends StatelessWidget {
  const _PacoteRow({
    required this.comparacao,
    required this.destacado,
  });

  final ComparacaoPacote comparacao;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final accent = comparacao.compensaria
        ? AppColors.neonGreen
        : AppColors.textSecondary;
    final diferenca = comparacao.economia.abs();
    final resultado = comparacao.compensaria
        ? 'Compensaria · economia de ${formatBrl(diferenca)}'
        : 'Não compensaria · ${formatBrl(diferenca)} a mais';
    final cobertura = comparacao.cobreTudo
        ? 'Cobriria as ${formatBrl(comparacao.taxasCobertas)} de taxa'
        : 'Melhor janela cobriria ${formatBrl(comparacao.taxasCobertas)} de ${formatBrl(comparacao.totalTaxas)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: destacado
            ? AppColors.neonGreen.withValues(alpha: 0.08)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: destacado
              ? AppColors.neonGreen.withValues(alpha: 0.45)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comparacao.pacote.label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: destacado ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
              Text(
                formatBrl(comparacao.pacote.preco),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            cobertura,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            resultado,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
