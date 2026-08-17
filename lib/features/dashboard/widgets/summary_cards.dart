import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/resumo_financeiro.dart';

class SummaryCards extends StatelessWidget {
  const SummaryCards({
    super.key,
    required this.resumo,
  });

  final ResumoFinanceiro resumo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SummaryTile(
          label: 'Total Bruto',
          value: formatBrl(resumo.totalBruto),
          subtitle:
              '${resumo.quantidadeCorridas} corrida(s) · Taxas ${formatBrl(resumo.totalTaxas)}',
          accent: AppColors.neonBlue,
          icon: Icons.trending_up_rounded,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: 'Total Gastos',
                value: formatBrl(resumo.totalGastos),
                accent: AppColors.expense,
                icon: Icons.local_gas_station_rounded,
                compact: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                label: 'Lucro Líquido',
                value: formatBrl(resumo.lucroLiquidoReal),
                accent: resumo.lucroLiquidoReal >= 0
                    ? AppColors.profit
                    : AppColors.danger,
                icon: Icons.account_balance_wallet_rounded,
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
    this.subtitle,
    this.compact = false,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Color accent;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: compact ? 18 : 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
