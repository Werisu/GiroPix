import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/meta_sonho.dart';
import '../../../providers/finance_provider.dart';
import 'meta_sonho_sheet.dart';

class MetaSonhoCard extends StatelessWidget {
  const MetaSonhoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final progresso = finance.progressoMeta();
    if (progresso == null) {
      return const _MetaVaziaCard();
    }
    return _MetaAtivaCard(progresso: progresso);
  }
}

class _MetaVaziaCard extends StatelessWidget {
  const _MetaVaziaCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showMetaSonhoEditor(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.neonGreen.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.neonGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.two_wheeler_rounded,
                        color: AppColors.neonGreen,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Seu sonho',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.add_rounded,
                      color: AppColors.neonGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Qual é o seu sonho?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Exemplo: conquistar uma moto esportiva. Defina o valor e vá guardando o lucro das corridas.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaAtivaCard extends StatelessWidget {
  const _MetaAtivaCard({required this.progresso});

  final ProgressoMeta progresso;

  @override
  Widget build(BuildContext context) {
    final meta = progresso.meta;
    final conquistada = meta.conquistada;
    final accent = conquistada ? AppColors.neonGreen : AppColors.neonBlue;
    final percent = (meta.progresso * 100).clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: conquistada
                ? AppColors.neonGreen.withValues(alpha: 0.45)
                : AppColors.border,
          ),
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
                  child: Icon(meta.tipo.icon, color: accent, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Seu sonho',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => showMetaSonhoEditor(context, atual: meta),
                  child: const Text('Editar'),
                ),
              ],
            ),
            Text(
              meta.titulo,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: meta.progresso,
                minHeight: 10,
                backgroundColor: AppColors.surfaceLight,
                color: accent,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${formatBrl(meta.valorGuardado)} de ${formatBrl(meta.valorAlvo)}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              conquistada
                  ? 'Você chegou lá. Hora de realizar o sonho.'
                  : 'Falta ${formatBrl(meta.restante)} · ${progresso.previsaoTexto()}',
              style: TextStyle(
                color: conquistada ? AppColors.neonGreen : AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
                fontWeight: conquistada ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (!conquistada) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => showGuardarNaMeta(context),
                  icon: const Icon(Icons.savings_outlined, size: 18),
                  label: const Text('Guardar na meta'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neonGreen,
                    side: BorderSide(
                      color: AppColors.neonGreen.withValues(alpha: 0.45),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
