import '../models/corrida.dart';
import '../models/gasto.dart';

class CloudRecord<T> {
  const CloudRecord({
    required this.id,
    required this.deleted,
    required this.updatedAt,
    this.item,
    this.foreign = false,
  });

  final String id;
  final bool deleted;
  final DateTime updatedAt;
  final T? item;
  final bool foreign;
}

class PendingDelete {
  const PendingDelete({
    required this.id,
    required this.type,
    required this.deletedAt,
  });

  final String id;
  final String type; // corrida | gasto
  final DateTime deletedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'deletedAt': deletedAt.toIso8601String(),
      };

  factory PendingDelete.fromJson(Map<String, dynamic> json) {
    return PendingDelete(
      id: json['id'] as String,
      type: json['type'] as String,
      deletedAt: DateTime.parse(json['deletedAt'] as String),
    );
  }
}

class SettingsSnapshot {
  const SettingsSnapshot({
    required this.taxaPadraoPercent,
    required this.plataformaPadrao,
    this.updatedAt,
  });

  final double taxaPadraoPercent;
  final String plataformaPadrao;
  final DateTime? updatedAt;

  DateTime get syncStamp =>
      (updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)).toUtc();
}

class MergeResult {
  const MergeResult({
    required this.corridas,
    required this.gastos,
    required this.settings,
    required this.pendingDeletes,
  });

  final List<Corrida> corridas;
  final List<Gasto> gastos;
  final SettingsSnapshot settings;
  final List<PendingDelete> pendingDeletes;
}

class SyncMerger {
  static List<Corrida> mergeCorridas({
    required List<Corrida> local,
    required List<CloudRecord<Corrida>> remote,
    required List<PendingDelete> pendingDeletes,
  }) {
    final byId = {for (final c in local) c.id: c};

    for (final r in remote) {
      _applyRecord(
        byId: byId,
        id: r.id,
        deleted: r.deleted || r.foreign,
        remoteStamp: r.updatedAt,
        remoteItem: r.item,
        localStamp: (c) => c.syncStamp,
      );
    }

    for (final pending in pendingDeletes.where((p) => p.type == 'corrida')) {
      final loc = byId[pending.id];
      if (loc != null && !loc.syncStamp.isAfter(pending.deletedAt)) {
        byId.remove(pending.id);
      }
    }

    return byId.values.toList();
  }

  static List<Gasto> mergeGastos({
    required List<Gasto> local,
    required List<CloudRecord<Gasto>> remote,
    required List<PendingDelete> pendingDeletes,
  }) {
    final byId = {for (final g in local) g.id: g};

    for (final r in remote) {
      _applyRecord(
        byId: byId,
        id: r.id,
        deleted: r.deleted || r.foreign,
        remoteStamp: r.updatedAt,
        remoteItem: r.item,
        localStamp: (g) => g.syncStamp,
      );
    }

    for (final pending in pendingDeletes.where((p) => p.type == 'gasto')) {
      final loc = byId[pending.id];
      if (loc != null && !loc.syncStamp.isAfter(pending.deletedAt)) {
        byId.remove(pending.id);
      }
    }

    return byId.values.toList();
  }

  static SettingsSnapshot mergeSettings({
    required SettingsSnapshot local,
    required SettingsSnapshot? remote,
  }) {
    if (remote == null) return local;
    if (remote.syncStamp.isAfter(local.syncStamp)) return remote;
    return local;
  }

  static void _applyRecord<T>({
    required Map<String, T> byId,
    required String id,
    required bool deleted,
    required DateTime remoteStamp,
    required T? remoteItem,
    required DateTime Function(T local) localStamp,
  }) {
    final loc = byId[id];
    if (deleted) {
      if (loc != null && !localStamp(loc).isAfter(remoteStamp)) {
        byId.remove(id);
      }
      return;
    }
    if (remoteItem == null) return;
    if (loc == null || remoteStamp.isAfter(localStamp(loc))) {
      byId[id] = remoteItem;
    }
  }

  /// Documento legado sem dono vale para a conta atual.
  /// Com `ownerUid`, só entra se for da mesma conta.
  static bool belongsToUser(String? ownerUid, String currentUid) {
    if (ownerUid == null || ownerUid.isEmpty) return true;
    return ownerUid == currentUid;
  }
}
