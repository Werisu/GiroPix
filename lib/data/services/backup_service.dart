import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../local/hive_service.dart';
import '../models/corrida.dart';
import '../models/gasto.dart';

enum BackupRestoreMode {
  /// Apaga dados locais e carrega o backup.
  replace,

  /// Mantém dados locais e faz upsert por id.
  merge,
}

class BackupException implements Exception {
  BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

class BackupImportResult {
  const BackupImportResult({
    required this.corridas,
    required this.gastos,
    required this.mode,
    this.taxaPadraoPercent,
  });

  final int corridas;
  final int gastos;
  final BackupRestoreMode mode;
  final double? taxaPadraoPercent;
}

class BackupService {
  static const int supportedVersion = 1;
  static const String appId = 'giropix';

  /// Monta o JSON a partir do Hive e grava em arquivo temporário.
  Future<File> exportToFile() async {
    final corridas = HiveService.corridas.values.map((c) => c.toJson()).toList();
    final gastos = HiveService.gastos.values.map((g) => g.toJson()).toList();

    final payload = <String, dynamic>{
      'version': supportedVersion,
      'app': appId,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'settings': {
        'taxaPadraoPercent': HiveService.getTaxaPadraoPercent(),
      },
      'corridas': corridas,
      'gastos': gastos,
    };

    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/giropix_backup_$stamp.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    return file;
  }

  /// Lê e valida o backup. Não altera dados se o parse falhar.
  Future<BackupImportResult> importFromFile(
    File file, {
    required BackupRestoreMode mode,
    bool applySettings = true,
  }) async {
    if (!await file.exists()) {
      throw BackupException('Arquivo de backup não encontrado.');
    }

    late final Map<String, dynamic> data;
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw BackupException('Formato de backup inválido.');
      }
      data = decoded;
    } on BackupException {
      rethrow;
    } on FormatException {
      throw BackupException('Arquivo corrompido ou não é um JSON válido.');
    } catch (_) {
      throw BackupException('Não foi possível ler o arquivo de backup.');
    }

    _validate(data);

    final corridasList = data['corridas'];
    final gastosList = data['gastos'];
    if (corridasList is! List || gastosList is! List) {
      throw BackupException('Backup incompleto: faltam corridas ou gastos.');
    }

    final corridas = <Corrida>[];
    final gastos = <Gasto>[];

    try {
      for (final item in corridasList) {
        if (item is! Map) {
          throw BackupException('Registro de corrida inválido no backup.');
        }
        corridas.add(
          Corrida.fromJson(Map<String, dynamic>.from(item)).copyWith(
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      }
      for (final item in gastosList) {
        if (item is! Map) {
          throw BackupException('Registro de gasto inválido no backup.');
        }
        gastos.add(
          Gasto.fromJson(Map<String, dynamic>.from(item)).copyWith(
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      }
    } on BackupException {
      rethrow;
    } catch (_) {
      throw BackupException('Dados do backup estão inconsistentes.');
    }

    double? taxaPadrao;
    final settings = data['settings'];
    if (settings is Map && settings['taxaPadraoPercent'] is num) {
      taxaPadrao = (settings['taxaPadraoPercent'] as num).toDouble();
    }

    // Só grava após validação completa.
    if (mode == BackupRestoreMode.replace) {
      await HiveService.corridas.clear();
      await HiveService.gastos.clear();
    }

    for (final c in corridas) {
      await HiveService.corridas.put(c.id, c);
    }
    for (final g in gastos) {
      await HiveService.gastos.put(g.id, g);
    }

    if (applySettings && taxaPadrao != null) {
      await HiveService.setTaxaPadraoPercent(taxaPadrao.clamp(0, 100));
    }

    return BackupImportResult(
      corridas: corridas.length,
      gastos: gastos.length,
      mode: mode,
      taxaPadraoPercent: applySettings ? taxaPadrao : null,
    );
  }

  void _validate(Map<String, dynamic> data) {
    final app = data['app'];
    if (app != appId) {
      throw BackupException('Este arquivo não é um backup do GiroPix.');
    }

    final version = data['version'];
    if (version is! int && version is! num) {
      throw BackupException('Versão do backup ausente ou inválida.');
    }
    final v = (version as num).toInt();
    if (v < 1 || v > supportedVersion) {
      throw BackupException(
        'Versão de backup não suportada ($v). Atualize o app.',
      );
    }
  }
}
