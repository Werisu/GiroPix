import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/developer_card.dart';
import '../../data/models/meta_sonho.dart';
import '../../data/models/passe_livre.dart';
import '../../data/services/backup_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../dashboard/widgets/meta_sonho_sheet.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;

  Future<void> _exportar() async {
    if (_busy) return;
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Backup de arquivo está disponível no app Android.',
          ),
        ),
      );
      return;
    }
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
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
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Importar backup está disponível no app Android.',
          ),
        ),
      );
      return;
    }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
          'Deseja também aplicar a taxa padrão (%), os preços do passe livre e a meta de sonho salvos no arquivo de backup?',
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

  Future<void> _sair() async {
    if (_busy) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sair da conta?'),
        content: const Text(
          'Você continua no app sem conta. Os lançamentos neste celular '
          'não serão apagados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    await context.read<AuthProvider>().signOut();
  }

  Future<void> _editarPrecosPasse() async {
    final finance = context.read<FinanceProvider>();
    final atuais = finance.precosPasseLivre;
    final horas6 = TextEditingController(text: formatInputBrl(atuais.horas6));
    final horas12 = TextEditingController(text: formatInputBrl(atuais.horas12));
    final horas24 = TextEditingController(text: formatInputBrl(atuais.horas24));

    final salvo = await showDialog<PrecosPasseLivre>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Preços do passe livre'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Use os valores da Maxim na sua cidade para comparar com a taxa do dia.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: horas6,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: '6 horas (R\$)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: horas12,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: '12 horas (R\$)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: horas24,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: '24 horas (R\$)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final v6 = parseBrl(horas6.text);
                final v12 = parseBrl(horas12.text);
                final v24 = parseBrl(horas24.text);
                if (v6 == null || v12 == null || v24 == null) return;
                Navigator.pop(
                  ctx,
                  PrecosPasseLivre(horas6: v6, horas12: v12, horas24: v24),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    horas6.dispose();
    horas12.dispose();
    horas24.dispose();

    if (salvo == null || !mounted) return;
    await finance.setPrecosPasseLivre(salvo);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preços do passe livre atualizados.')),
    );
  }

  Future<void> _entrar() async {
    if (_busy) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final ok = await auth.signInWithGoogle();
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Conta conectada.')));
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final auth = context.watch<AuthProvider>();

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
              if (auth.isAuthenticated)
                _AccountCard(
                  displayName: auth.displayName,
                  email: auth.email,
                  photoUrl: auth.photoUrl,
                  busy: auth.busy || _busy,
                  onSignOut: _sair,
                )
              else
                _GuestAccountCard(
                  busy: auth.busy || _busy,
                  showGoogleSignIn: auth.googleSignInAvailable,
                  onSignIn: _entrar,
                ),
              if (auth.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  auth.error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              _CloudSyncCard(
                authenticated: auth.isAuthenticated,
                available: finance.cloudSyncAvailable,
                enabled: finance.cloudSyncEnabled,
                syncing: finance.syncing || _busy,
                lastSyncAt: finance.lastSyncAt,
                error: finance.syncError,
                onSync: finance.syncing || _busy
                    ? null
                    : () => finance.sincronizar(),
              ),
              const SizedBox(height: 20),
              _ActionCard(
                icon: Icons.confirmation_number_outlined,
                title: 'Passe livre Maxim',
                subtitle:
                    '6h ${formatBrl(finance.precosPasseLivre.horas6)} · '
                    '12h ${formatBrl(finance.precosPasseLivre.horas12)} · '
                    '24h ${formatBrl(finance.precosPasseLivre.horas24)}',
                accent: AppColors.neonBlue,
                onTap: _busy ? null : _editarPrecosPasse,
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: finance.metaSonho?.tipo.icon ?? Icons.flag_rounded,
                title: 'Meta do sonho',
                subtitle: finance.metaSonho == null
                    ? 'Ex: conquistar uma moto esportiva'
                    : '${finance.metaSonho!.titulo} · '
                        '${formatBrl(finance.metaSonho!.valorGuardado)} de '
                        '${formatBrl(finance.metaSonho!.valorAlvo)}',
                accent: AppColors.neonGreen,
                onTap: _busy
                    ? null
                    : () => showMetaSonhoEditor(
                          context,
                          atual: finance.metaSonho,
                        ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Backup em arquivo',
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
            const ModalBarrier(dismissible: false, color: Color(0x66000000)),
          if (_busy)
            const Center(
              child: CircularProgressIndicator(color: AppColors.neonGreen),
            ),
        ],
      ),
    );
  }
}

class _CloudSyncCard extends StatelessWidget {
  const _CloudSyncCard({
    required this.authenticated,
    required this.available,
    required this.enabled,
    required this.syncing,
    required this.lastSyncAt,
    required this.error,
    required this.onSync,
  });

  final bool authenticated;
  final bool available;
  final bool enabled;
  final bool syncing;
  final DateTime? lastSyncAt;
  final String? error;
  final VoidCallback? onSync;

  @override
  Widget build(BuildContext context) {
    final statusColor = error != null
        ? AppColors.danger
        : enabled
            ? AppColors.neonGreen
            : AppColors.neonBlue;

    String subtitle;
    if (!available) {
      subtitle =
          'A nuvem está disponível no app Android. Aqui os dados ficam só neste dispositivo.';
    } else if (!authenticated) {
      subtitle =
          'Entre com Google para enviar corridas e gastos ao Cloud Firestore e recuperar em outro celular.';
    } else if (syncing) {
      subtitle = 'Sincronizando com a nuvem…';
    } else if (error != null) {
      subtitle = error!;
    } else if (lastSyncAt != null) {
      final stamp = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR')
          .format(lastSyncAt!.toLocal());
      subtitle = 'Última sincronização: $stamp';
    } else {
      subtitle = 'A conta está ligada. Toque para sincronizar agora.';
    }

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
          Row(
            children: [
              Icon(Icons.cloud_sync_rounded, color: statusColor, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Sincronização na nuvem',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (syncing && enabled)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.neonGreen,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (enabled) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSync,
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: Text(error != null ? 'Tentar de novo' : 'Sincronizar agora'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
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
    );
  }
}

class _GuestAccountCard extends StatelessWidget {
  const _GuestAccountCard({
    required this.busy,
    required this.showGoogleSignIn,
    required this.onSignIn,
  });

  final bool busy;
  final bool showGoogleSignIn;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
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
            'Conta',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Usando sem conta',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            showGoogleSignIn
                ? 'Os lançamentos ficam neste celular. Entre com Google para '
                    'sincronizar na nuvem e recuperar em outro aparelho.'
                : 'No navegador o app roda sem conta. Login com Google está '
                    'disponível no app Android.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (showGoogleSignIn) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: busy ? null : onSignIn,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 22),
                label: const Text('Entrar com Google'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
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
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.busy,
    required this.onSignOut,
  });

  final String? displayName;
  final String? email;
  final String? photoUrl;
  final bool busy;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final name = (displayName != null && displayName!.trim().isNotEmpty)
        ? displayName!.trim()
        : 'Conta Google';
    final mail = email ?? '';

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
            'Conta',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceLight,
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl!)
                    : null,
                child: photoUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.neonGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (mail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        mail,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onSignOut,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sair da conta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(
                  color: AppColors.danger.withValues(alpha: 0.45),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
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
