import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class PaymentSelector extends StatelessWidget {
  const PaymentSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  static const options = [
    (label: 'Pix', icon: Icons.qr_code_2_rounded, color: AppColors.neonGreen),
    (label: 'Dinheiro', icon: Icons.payments_rounded, color: AppColors.warning),
    (label: 'Cartão', icon: Icons.credit_card_rounded, color: AppColors.neonBlue),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final isSelected = selected == opt.label;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: opt.label != 'Cartão' ? 10 : 0,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(opt.label),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 18),
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
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        opt.label,
                        style: TextStyle(
                          color: isSelected
                              ? opt.color
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
