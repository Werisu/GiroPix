import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class PlatformSelector extends StatelessWidget {
  const PlatformSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  static const options = [
    (label: '99', icon: Icons.local_taxi_rounded, color: AppColors.warning),
    (
      label: 'iFood',
      icon: Icons.delivery_dining_rounded,
      color: AppColors.danger,
    ),
    (
      label: 'Maxim',
      icon: Icons.directions_car_rounded,
      color: AppColors.neonBlue,
    ),
    (
      label: 'Outro',
      icon: Icons.more_horiz_rounded,
      color: AppColors.neonGreen,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _chip(options[0]),
            const SizedBox(width: 10),
            _chip(options[1]),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _chip(options[2]),
            const SizedBox(width: 10),
            _chip(options[3]),
          ],
        ),
      ],
    );
  }

  Widget _chip(({String label, IconData icon, Color color}) opt) {
    final isSelected = selected == opt.label;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(opt.label),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? opt.color.withValues(alpha: 0.15)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? opt.color : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  opt.icon,
                  color: isSelected ? opt.color : AppColors.textSecondary,
                  size: 26,
                ),
                const SizedBox(height: 6),
                Text(
                  opt.label,
                  style: TextStyle(
                    color: isSelected ? opt.color : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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
