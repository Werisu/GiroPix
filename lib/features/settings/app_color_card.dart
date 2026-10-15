import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/theme_provider.dart';

class AppColorCard extends StatelessWidget {
  const AppColorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final atual = context.watch<ThemeProvider>().palette;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cores do app',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Destaque atual: ${atual.label}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              for (final palette in AppPalette.presets)
                _Swatch(
                  palette: palette,
                  selected: palette.id == atual.id,
                  onTap: () => context.read<ThemeProvider>().setPalette(palette),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: palette.label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [palette.primary, palette.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: selected ? AppColors.textPrimary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: selected
                  ? Icon(Icons.check_rounded, color: palette.onPrimary, size: 20)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              palette.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
