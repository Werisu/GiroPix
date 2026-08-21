import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../local/hive_service.dart';
import '../models/corrida.dart';
import '../models/gasto.dart';
import '../models/meta_sonho.dart';
import '../models/passe_livre.dart';
import 'sync_merger.dart';

class CloudSyncException implements Exception {
  CloudSyncException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Sincroniza Hive ↔ Cloud Firestore para o usuário autenticado.
/// Hive continua sendo a fonte da UI; a nuvem replica e recupera em outro aparelho.
class FirestoreSyncService {
  FirestoreSyncService({FirebaseFirestore? firestore})
      : _firestore = firestore ??
            (Firebase.apps.isEmpty ? null : FirebaseFirestore.instance);

  final FirebaseFirestore? _firestore;

  bool get isAvailable => _firestore != null && !kIsWeb;

  CollectionReference<Map<String, dynamic>> _corridas(String uid) =>
      _firestore!.collection('users').doc(uid).collection('corridas');

  CollectionReference<Map<String, dynamic>> _gastos(String uid) =>
      _firestore!.collection('users').doc(uid).collection('gastos');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore!.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _settings(String uid) =>
      _userDoc(uid).collection('meta').doc('settings');

  Future<void> upsertCorrida(String uid, Corrida corrida) async {
    if (!isAvailable) return;
    await _corridas(uid).doc(corrida.id).set(_corridaToMap(corrida, uid));
  }

  Future<void> upsertGasto(String uid, Gasto gasto) async {
    if (!isAvailable) return;
    await _gastos(uid).doc(gasto.id).set(_gastoToMap(gasto, uid));
  }

  Future<void> upsertSettings(String uid, SettingsSnapshot settings) async {
    if (!isAvailable) return;
    await _settings(uid).set(_settingsToMap(settings));
  }

  Future<void> tombstoneCorrida(String uid, String id, DateTime deletedAt) async {
    if (!isAvailable) return;
    await _corridas(uid).doc(id).set({
      'id': id,
      'deleted': true,
      'ownerUid': uid,
      'updatedAt': deletedAt.toUtc().toIso8601String(),
    });
  }

  Future<void> tombstoneGasto(String uid, String id, DateTime deletedAt) async {
    if (!isAvailable) return;
    await _gastos(uid).doc(id).set({
      'id': id,
      'deleted': true,
      'ownerUid': uid,
      'updatedAt': deletedAt.toUtc().toIso8601String(),
    });
  }

  /// Mescla nuvem + local, grava no Hive e envia o resultado à nuvem.
  Future<void> syncAll(String uid, {bool pruneRemote = false}) async {
    if (!isAvailable) {
      throw CloudSyncException('Sincronização na nuvem indisponível neste dispositivo.');
    }

    await _ensureUserProfile(uid);

    var pending = HiveService.getPendingDeletes();

    final remoteCorridas = await _loadCorridas(uid);
    final remoteGastos = await _loadGastos(uid);
    final remoteSettings = await _loadSettings(uid);

    final now = DateTime.now().toUtc();
    pending = [
      ...pending,
      ...remoteCorridas.where((r) => r.foreign).map(
            (r) => PendingDelete(id: r.id, type: 'corrida', deletedAt: now),
          ),
      ...remoteGastos.where((r) => r.foreign).map(
            (r) => PendingDelete(id: r.id, type: 'gasto', deletedAt: now),
          ),
    ];

    if (pruneRemote) {
      final pruneAt = DateTime.now().toUtc();
      final localCorridaIds = HiveService.corridas.keys.toSet();
      final localGastoIds = HiveService.gastos.keys.toSet();
      pending = [
        ...pending,
        ...remoteCorridas
            .where((r) => !r.deleted && !r.foreign && !localCorridaIds.contains(r.id))
            .map(
              (r) => PendingDelete(id: r.id, type: 'corrida', deletedAt: pruneAt),
            ),
        ...remoteGastos
            .where((r) => !r.deleted && !r.foreign && !localGastoIds.contains(r.id))
            .map((r) => PendingDelete(id: r.id, type: 'gasto', deletedAt: pruneAt)),
      ];
    }
    await HiveService.setPendingDeletes(pending);

    final mergedCorridas = SyncMerger.mergeCorridas(
      local: HiveService.corridas.values.toList(),
      remote: remoteCorridas,
      pendingDeletes: pending,
    );
    final mergedGastos = SyncMerger.mergeGastos(
      local: HiveService.gastos.values.toList(),
      remote: remoteGastos,
      pendingDeletes: pending,
    );
    final mergedSettings = SyncMerger.mergeSettings(
      local: SettingsSnapshot(
        taxaPadraoPercent: HiveService.getTaxaPadraoPercent(),
        plataformaPadrao: HiveService.getPlataformaPadrao(),
        updatedAt: HiveService.getSettingsUpdatedAt(),
        precosPasseLivre: HiveService.getPrecosPasseLivre(),
        metaSonho: HiveService.getMetaSonho(),
      ),
      remote: remoteSettings,
    );

    await _replaceLocal(mergedCorridas, mergedGastos, mergedSettings);

    await _pushSnapshot(
      uid: uid,
      corridas: mergedCorridas,
      gastos: mergedGastos,
      settings: mergedSettings,
      pendingDeletes: pending,
    );

    await HiveService.clearPendingDeletes();
    await HiveService.setLastSyncAt(DateTime.now().toUtc());
  }

  Future<void> _ensureUserProfile(String uid) async {
    await _userDoc(uid).set({
      'uid': uid,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<List<CloudRecord<Corrida>>> _loadCorridas(String uid) async {
    final snap = await _corridas(uid).get();
    return snap.docs
        .map((doc) => _corridaFromDoc(doc, uid))
        .whereType<CloudRecord<Corrida>>()
        .toList();
  }

  Future<List<CloudRecord<Gasto>>> _loadGastos(String uid) async {
    final snap = await _gastos(uid).get();
    return snap.docs
        .map((doc) => _gastoFromDoc(doc, uid))
        .whereType<CloudRecord<Gasto>>()
        .toList();
  }

  Future<SettingsSnapshot?> _loadSettings(String uid) async {
    final snap = await _settings(uid).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    final taxa = (data['taxaPadraoPercent'] as num?)?.toDouble();
    if (taxa == null) return null;
    return SettingsSnapshot(
      taxaPadraoPercent: taxa,
      plataformaPadrao: data['plataformaPadrao'] as String? ??
          HiveService.plataformaPadraoDefault,
      updatedAt: parseFirestoreDate(data['updatedAt']),
      precosPasseLivre: PrecosPasseLivre(
        horas6: (data['passeLivre6h'] as num?)?.toDouble() ??
            HiveService.getPrecosPasseLivre().horas6,
        horas12: (data['passeLivre12h'] as num?)?.toDouble() ??
            HiveService.getPrecosPasseLivre().horas12,
        horas24: (data['passeLivre24h'] as num?)?.toDouble() ??
            HiveService.getPrecosPasseLivre().horas24,
      ),
      metaSonho: _metaFromMap(data['metaSonho']),
      metaSonhoDefined: data.containsKey('metaSonho'),
    );
  }

  Future<void> _replaceLocal(
    List<Corrida> corridas,
    List<Gasto> gastos,
    SettingsSnapshot settings,
  ) async {
    final keepCorridas = corridas.map((c) => c.id).toSet();
    final keepGastos = gastos.map((g) => g.id).toSet();

    final toRemoveCorridas = HiveService.corridas.keys
        .where((k) => !keepCorridas.contains(k))
        .toList();
    final toRemoveGastos = HiveService.gastos.keys
        .where((k) => !keepGastos.contains(k))
        .toList();

    for (final key in toRemoveCorridas) {
      await HiveService.corridas.delete(key);
    }
    for (final key in toRemoveGastos) {
      await HiveService.gastos.delete(key);
    }
    for (final c in corridas) {
      await HiveService.corridas.put(c.id, c);
    }
    for (final g in gastos) {
      await HiveService.gastos.put(g.id, g);
    }

    await HiveService.setTaxaPadraoPercent(settings.taxaPadraoPercent);
    await HiveService.setPlataformaPadrao(settings.plataformaPadrao);
    await HiveService.setPrecosPasseLivre(settings.precosPasseLivre);
    if (settings.metaSonhoDefined) {
      await HiveService.setMetaSonho(settings.metaSonho);
    }
    if (settings.updatedAt != null) {
      await HiveService.setSettingsUpdatedAt(settings.updatedAt!);
    }
  }

  Future<void> _pushSnapshot({
    required String uid,
    required List<Corrida> corridas,
    required List<Gasto> gastos,
    required SettingsSnapshot settings,
    required List<PendingDelete> pendingDeletes,
  }) async {
    final ops = <_BatchOp>[
      ...corridas.map(
        (c) => _BatchOp(_corridas(uid).doc(c.id), _corridaToMap(c, uid)),
      ),
      ...gastos.map(
        (g) => _BatchOp(_gastos(uid).doc(g.id), _gastoToMap(g, uid)),
      ),
      _BatchOp(_settings(uid), _settingsToMap(settings)),
      ...pendingDeletes.where((p) {
        final kept = p.type == 'gasto'
            ? gastos.any((g) => g.id == p.id)
            : corridas.any((c) => c.id == p.id);
        return !kept;
      }).map((p) {
        final col = p.type == 'gasto' ? _gastos(uid) : _corridas(uid);
        return _BatchOp(col.doc(p.id), {
          'id': p.id,
          'deleted': true,
          'ownerUid': uid,
          'updatedAt': p.deletedAt.toUtc().toIso8601String(),
        });
      }),
    ];

    const chunkSize = 450;
    for (var i = 0; i < ops.length; i += chunkSize) {
      final batch = _firestore!.batch();
      for (final op in ops.skip(i).take(chunkSize)) {
        batch.set(op.ref, op.data);
      }
      await batch.commit();
    }
  }

  CloudRecord<Corrida>? _corridaFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String uid,
  ) {
    final data = doc.data();
    final id = data['id'] as String? ?? doc.id;
    final updatedAt = parseFirestoreDate(data['updatedAt']) ??
        parseFirestoreDate(data['dataHora']) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final deleted = data['deleted'] == true;
    final foreign = !SyncMerger.belongsToUser(
      data['ownerUid'] as String?,
      uid,
    );
    if (deleted || foreign) {
      return CloudRecord(
        id: id,
        deleted: deleted,
        foreign: foreign,
        updatedAt: updatedAt,
      );
    }
    try {
      return CloudRecord(
        id: id,
        deleted: false,
        updatedAt: updatedAt,
        item: Corrida(
          id: id,
          dataHora: parseFirestoreDate(data['dataHora']) ?? updatedAt,
          valorBruto: (data['valorBruto'] as num?)?.toDouble() ?? 0,
          formaPagamento: data['formaPagamento'] as String? ?? 'Pix',
          taxaApp: (data['taxaApp'] as num?)?.toDouble() ?? 0,
          plataforma: data['plataforma'] as String? ?? 'Outro',
          updatedAt: parseFirestoreDate(data['updatedAt']),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  CloudRecord<Gasto>? _gastoFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String uid,
  ) {
    final data = doc.data();
    final id = data['id'] as String? ?? doc.id;
    final updatedAt = parseFirestoreDate(data['updatedAt']) ??
        parseFirestoreDate(data['data']) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final deleted = data['deleted'] == true;
    final foreign = !SyncMerger.belongsToUser(
      data['ownerUid'] as String?,
      uid,
    );
    if (deleted || foreign) {
      return CloudRecord(
        id: id,
        deleted: deleted,
        foreign: foreign,
        updatedAt: updatedAt,
      );
    }
    try {
      return CloudRecord(
        id: id,
        deleted: false,
        updatedAt: updatedAt,
        item: Gasto(
          id: id,
          data: parseFirestoreDate(data['data']) ?? updatedAt,
          combustivel: (data['combustivel'] as num?)?.toDouble() ?? 0,
          alimentacao: (data['alimentacao'] as num?)?.toDouble() ?? 0,
          outros: (data['outros'] as num?)?.toDouble() ?? 0,
          updatedAt: parseFirestoreDate(data['updatedAt']),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _corridaToMap(Corrida c, String uid) => {
        'id': c.id,
        'dataHora': c.dataHora.toIso8601String(),
        'valorBruto': c.valorBruto,
        'formaPagamento': c.formaPagamento,
        'taxaApp': c.taxaApp,
        'plataforma': c.plataforma,
        'updatedAt': c.syncStamp.toUtc().toIso8601String(),
        'deleted': false,
        'ownerUid': uid,
      };

  Map<String, dynamic> _gastoToMap(Gasto g, String uid) => {
        'id': g.id,
        'data': g.data.toIso8601String(),
        'combustivel': g.combustivel,
        'alimentacao': g.alimentacao,
        'outros': g.outros,
        'updatedAt': g.syncStamp.toUtc().toIso8601String(),
        'deleted': false,
        'ownerUid': uid,
      };

  MetaSonho? _metaFromMap(dynamic raw) {
    if (raw is! Map) return null;
    try {
      return MetaSonho.fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _settingsToMap(SettingsSnapshot s) => {
        'taxaPadraoPercent': s.taxaPadraoPercent,
        'plataformaPadrao': s.plataformaPadrao,
        'passeLivre6h': s.precosPasseLivre.horas6,
        'passeLivre12h': s.precosPasseLivre.horas12,
        'passeLivre24h': s.precosPasseLivre.horas24,
        'metaSonho': s.metaSonho?.toJson(),
        'updatedAt': s.syncStamp.toUtc().toIso8601String(),
      };
}

class _BatchOp {
  const _BatchOp(this.ref, this.data);
  final DocumentReference<Map<String, dynamic>> ref;
  final Map<String, dynamic> data;
}

DateTime? parseFirestoreDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
