import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/developer_info.dart';
import '../theme/app_theme.dart';

class DeveloperCard extends StatelessWidget {
  const DeveloperCard({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link.')),
        );
      }
    }
  }

  Future<void> _copy(BuildContext context, String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label copiado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.code_rounded,
                color: AppColors.neonGreen,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Desenvolvedor',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            DeveloperInfo.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'GiroPix — controle financeiro para motoboys',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          _ContactTile(
            icon: Icons.email_outlined,
            label: 'E-mail',
            value: DeveloperInfo.email,
            accent: AppColors.neonBlue,
            onTap: () => _open(context, DeveloperInfo.emailUri),
            onLongPress: () =>
                _copy(context, DeveloperInfo.email, 'E-mail'),
          ),
          const SizedBox(height: 8),
          _ContactTile(
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            value: DeveloperInfo.whatsappDisplay,
            accent: AppColors.neonGreen,
            onTap: () => _open(context, DeveloperInfo.whatsappUri),
            onLongPress: () =>
                _copy(context, DeveloperInfo.whatsappDisplay, 'WhatsApp'),
          ),
          const SizedBox(height: 8),
          _ContactTile(
            icon: Icons.link_rounded,
            label: 'LinkedIn',
            value: 'wellyssonrocha-front-end',
            accent: AppColors.neonCyan,
            onTap: () => _open(context, DeveloperInfo.linkedInUrl),
            onLongPress: () =>
                _copy(context, DeveloperInfo.linkedInUrl, 'LinkedIn'),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.onTap,
    required this.onLongPress,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: accent.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
