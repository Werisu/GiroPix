import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'widgets/corrida_form.dart';
import 'widgets/gasto_form.dart';

class RegistroScreen extends StatelessWidget {
  const RegistroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [AppColors.neonGreen, AppColors.neonBlue],
                    ),
                  ),
                  labelColor: const Color(0xFF001A10),
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.two_wheeler_rounded, size: 20),
                      text: 'Corrida',
                      height: 56,
                    ),
                    Tab(
                      icon: Icon(Icons.receipt_long_rounded, size: 20),
                      text: 'Gastos',
                      height: 56,
                    ),
                  ],
                ),
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  CorridaForm(),
                  GastoForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
