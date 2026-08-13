import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../backup/backup_screen.dart';
import 'widgets/earnings_chart.dart';
import 'widgets/period_filter.dart';
import 'widgets/summary_cards.dart';
import 'widgets/worked_days_calendar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, finance, _) {
        if (finance.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.neonGreen),
          );
        }

        final resumo = finance.resumoDoPeriodo();
        final chartData = finance.ganhosDoPeriodo();

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.neonGreen,
                                  AppColors.neonBlue,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.two_wheeler_rounded,
                              color: Color(0xFF001A10),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'GiroPix',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  context.watch<AuthProvider>().isGuest
                                      ? 'Sem conta — dados só neste celular'
                                      : 'Seu controle financeiro na rua',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Configurações',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const BackupScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.settings_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      PeriodFilter(
                        selected: finance.periodo,
                        onChanged: finance.setPeriodo,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Resumo — ${finance.periodo.label}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SummaryCards(resumo: resumo),
                      const SizedBox(height: 20),
                      const WorkedDaysCalendar(),
                      const SizedBox(height: 20),
                      EarningsChart(data: chartData, periodo: finance.periodo),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
