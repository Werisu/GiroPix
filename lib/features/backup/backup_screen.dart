import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/developer_card.dart';
import '../../data/services/backup_service.dart';
import '../../providers/finance_provider.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;

  Future<void> _exportar() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final finance = context.read<FinanceProvider>();
      final file = await finance.exportBackup();

      if (!mounted) return;

      final params = ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Backup GiroPix',
        text:
            'Backup do GiroPix — ${finance.corridas.length} corridas, '
            '${finance.gastos.length} gastos. Guarde este arquivo em local seguro.',
      );
      await SharePlus.instance.share(params);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup gerado. Salve em Drive, WhatsApp ou Arquivos.'),
        ),
      );
    } on BackupException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao exportar o backup.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importar() async {
    if (_busy) return;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: false,
    );

    if (picked == null || picked.files.isEmpty) return;

    final path = picked.files.single.path;
    if (path == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível acessar o arquivo.')),
      );
      return;
    }

    if (!mounted) return;
    final mode = await _escolherModoRestauracao();
    if (mode == null || !mounted) return;

    final applySettings = mode == BackupRestoreMode.replace
        ? true
        : await _confirmarAplicarSettings() ?? false;

    if (!mounted) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Confirmar restauração'),
        content: Text(
          mode == BackupRestoreMode.replace
              ? 'Todos os dados atuais serão apagados e substituídos pelo backup. Esta ação não pode ser desfeita.'
              : 'Os lançamentos do backup serão mesclados com os dados atuais. Itens com o mesmo ID serão sobrescritos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: mode == BackupRestoreMode.replace
                  ? AppColors.danger
                  : AppColors.neonGreen,
            ),
            child: Text(
              mode == BackupRestoreMode.replace ? 'Substituir tudo' : 'Mesclar',
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final result = await context.read<FinanceProvider>().importBackup(
            File(path),
            mode: mode,
            applySettings: applySettings,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restauração concluída: ${result.corridas} corridas e '
            '${result.gastos} gastos '
            '(${result.mode == BackupRestoreMode.replace ? 'substituído' : 'mesclado'}).',
          ),
        ),
      );
    } on BackupException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Falha ao importar. Seus dados locais não foram alterados.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<BackupRestoreMode?> _escolherModoRestauracao() {
    return showModalBottomSheet<BackupRestoreMode>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Como restaurar?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Escolha o modo de importação do arquivo.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                _ModeTile(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Substituir tudo',
                  subtitle: 'Recomendado ao trocar de celular. Apaga o atual.',
                  accent: AppColors.danger,
                  onTap: () => Navigator.pop(ctx, BackupRestoreMode.replace),
                ),
                const SizedBox(height: 10),
                _ModeTile(
                  icon: Icons.merge_type_rounded,
                  title: 'Mesclar',
                  subtitle: 'Mantém o que já existe e unifica por ID.',
                  accent: AppColors.neonBlue,
                  onTap: () => Navigator.pop(ctx, BackupRestoreMode.merge),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmarAplicarSettings() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Configurações do backup'),
        content: const Text(
          'Deseja também aplicar a taxa padrão (%) salva no arquivo de backup?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim, aplicar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _busy ? null : () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.neonBlue,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Seus dados ficam só neste celular',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Exporte um arquivo JSON e salve fora do app (Drive, '
                      'WhatsApp, e-mail ou pasta Arquivos). Se desinstalar o '
                      'app sem backup, os lançamentos são perdidos.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Backup',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Agora: ${finance.corridas.length} corridas · '
                '${finance.gastos.length} gastos',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              _ActionCard(
                icon: Icons.upload_file_rounded,
                title: 'Exportar backup',
                subtitle: 'Gera um JSON e abre a tela de compartilhar',
                accent: AppColors.neonGreen,
                onTap: _busy ? null : _exportar,
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.download_rounded,
                title: 'Importar backup',
                subtitle: 'Restaura a partir de um arquivo .json',
                accent: AppColors.neonBlue,
                onTap: _busy ? null : _importar,
              ),
              const SizedBox(height: 28),
              const DeveloperCard(),
            ],
          ),
          if (_busy)
            const ModalBarrier(
              dismissible: false,
              color: Color(0x66000000),
            ),
          if (_busy)
            const Center(
              child: CircularProgressIndicator(color: AppColors.neonGreen),
            ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: onTap == null
                    ? AppColors.border
                    : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
