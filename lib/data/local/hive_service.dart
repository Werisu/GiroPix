import 'package:hive_flutter/hive_flutter.dart';

import '../models/corrida.dart';
import '../models/gasto.dart';
import '../models/passe_livre.dart';
import '../services/sync_merger.dart';

class HiveService {
  static const String corridasBox = 'corridas';
  static const String gastosBox = 'gastos';
  static const String settingsBox = 'settings';

  static const String keyTaxaPadraoPercent = 'taxa_padrao_percent';
  static const String keyPlataformaPadrao = 'plataforma_padrao';
  static const String keyGuestMode = 'guest_mode';
  static const String keyLastSyncAt = 'last_sync_at';
  static const String keySettingsUpdatedAt = 'settings_updated_at';
  static const String keyPendingDeletes = 'pending_deletes';
  static const String keyDataOwnerUid = 'data_owner_uid';
  static const String keyPasseLivre6h = 'passe_livre_6h';
  static const String keyPasseLivre12h = 'passe_livre_12h';
  static const String keyPasseLivre24h = 'passe_livre_24h';
  static const double taxaPadraoDefault = 15.0;
  static const String plataformaPadraoDefault = '99';

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CorridaAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(GastoAdapter());
    }

    await Future.wait([
      Hive.openBox<Corrida>(corridasBox),
      Hive.openBox<Gasto>(gastosBox),
      Hive.openBox(settingsBox),
    ]);
  }

  static Box<Corrida> get corridas => Hive.box<Corrida>(corridasBox);
  static Box<Gasto> get gastos => Hive.box<Gasto>(gastosBox);
  static Box get settings => Hive.box(settingsBox);

  static double getTaxaPadraoPercent() {
    return (settings.get(keyTaxaPadraoPercent) as num?)?.toDouble() ??
        taxaPadraoDefault;
  }

  static Future<void> setTaxaPadraoPercent(double percent) async {
    await settings.put(keyTaxaPadraoPercent, percent);
  }

  static String getPlataformaPadrao() {
    final value = settings.get(keyPlataformaPadrao) as String?;
    if (value == null || value.isEmpty) return plataformaPadraoDefault;
    if (value == 'Uber') return 'Maxim';
    return value;
  }

  static Future<void> setPlataformaPadrao(String plataforma) async {
    await settings.put(keyPlataformaPadrao, plataforma);
  }

  static PrecosPasseLivre getPrecosPasseLivre() {
    return PrecosPasseLivre(
      horas6: _readPassePreco(keyPasseLivre6h, PrecosPasseLivre.padrao6h),
      horas12: _readPassePreco(keyPasseLivre12h, PrecosPasseLivre.padrao12h),
      horas24: _readPassePreco(keyPasseLivre24h, PrecosPasseLivre.padrao24h),
    );
  }

  static Future<void> setPrecosPasseLivre(PrecosPasseLivre precos) async {
    await settings.put(keyPasseLivre6h, precos.horas6);
    await settings.put(keyPasseLivre12h, precos.horas12);
    await settings.put(keyPasseLivre24h, precos.horas24);
  }

  static double _readPassePreco(String key, double fallback) {
    final value = (settings.get(key) as num?)?.toDouble();
    if (value == null || value < 0) return fallback;
    return value;
  }

  static bool getGuestMode() => settings.get(keyGuestMode) == true;

  static Future<void> setGuestMode(bool enabled) async {
    await settings.put(keyGuestMode, enabled);
  }

  static DateTime? getLastSyncAt() {
    final raw = settings.get(keyLastSyncAt) as String?;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static Future<void> setLastSyncAt(DateTime at) async {
    await settings.put(keyLastSyncAt, at.toUtc().toIso8601String());
  }

  static DateTime? getSettingsUpdatedAt() {
    final raw = settings.get(keySettingsUpdatedAt) as String?;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static Future<void> setSettingsUpdatedAt(DateTime at) async {
    await settings.put(keySettingsUpdatedAt, at.toUtc().toIso8601String());
  }

  static List<PendingDelete> getPendingDeletes() {
    final raw = settings.get(keyPendingDeletes);
    if (raw is! List) return <PendingDelete>[];
    final result = <PendingDelete>[];
    for (final item in raw) {
      if (item is Map) {
        try {
          result.add(
            PendingDelete.fromJson(Map<String, dynamic>.from(item)),
          );
        } catch (_) {}
      }
    }
    return result;
  }

  static Future<void> addPendingDelete(PendingDelete delete) async {
    final current = List<PendingDelete>.from(getPendingDeletes());
    current.removeWhere((p) => p.id == delete.id && p.type == delete.type);
    current.add(delete);
    await setPendingDeletes(current);
  }

  static Future<void> setPendingDeletes(List<PendingDelete> deletes) async {
    await settings.put(
      keyPendingDeletes,
      deletes.map((p) => p.toJson()).toList(),
    );
  }

  static Future<void> clearPendingDeletes() async {
    await settings.put(keyPendingDeletes, <Map<String, dynamic>>[]);
  }

  static String? getDataOwnerUid() {
    final value = settings.get(keyDataOwnerUid) as String?;
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static Future<void> setDataOwnerUid(String uid) async {
    await settings.put(keyDataOwnerUid, uid);
  }

  /// Apaga lançamentos locais ao trocar de conta, sem misturar na nuvem da outra.
  static Future<void> clearFinanceData() async {
    await corridas.clear();
    await gastos.clear();
    await clearPendingDeletes();
    await settings.delete(keyLastSyncAt);
    await settings.delete(keySettingsUpdatedAt);
    await settings.put(keyTaxaPadraoPercent, taxaPadraoDefault);
    await settings.put(keyPlataformaPadrao, plataformaPadraoDefault);
    await setPrecosPasseLivre(const PrecosPasseLivre());
  }
}
