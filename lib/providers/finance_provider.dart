import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/utils/date_helpers.dart';
import '../data/local/hive_service.dart';
import '../data/models/corrida.dart';
import '../data/models/gasto.dart';
import '../data/models/meta_sonho.dart';
import '../data/models/passe_livre.dart';
import '../data/models/resumo_financeiro.dart';
import '../data/repositories/corrida_repository.dart';
import '../data/repositories/gasto_repository.dart';
import '../data/services/backup_service.dart';
import '../data/services/firestore_sync_service.dart';
import '../data/services/sync_merger.dart';

/// Item unificado para o histórico (corrida ou gasto).
sealed class HistoricoItem {
  DateTime get dataHora;
}

class HistoricoCorrida extends HistoricoItem {
  final Corrida corrida;
  HistoricoCorrida(this.corrida);

  @override
  DateTime get dataHora => corrida.dataHora;
}

class HistoricoGasto extends HistoricoItem {
  final Gasto gasto;
  HistoricoGasto(this.gasto);

  @override
  DateTime get dataHora => gasto.data;
}

class FinanceProvider extends ChangeNotifier {
  FinanceProvider({
    CorridaRepository? corridaRepository,
    GastoRepository? gastoRepository,
    BackupService? backupService,
    FirestoreSyncService? syncService,
  }) : _corridaRepo = corridaRepository ?? CorridaRepository(),
       _gastoRepo = gastoRepository ?? GastoRepository(),
       _backupService = backupService ?? BackupService(),
       _syncService = syncService ?? FirestoreSyncService();

  final CorridaRepository _corridaRepo;
  final GastoRepository _gastoRepo;
  final BackupService _backupService;
  final FirestoreSyncService _syncService;

  List<Corrida> _corridas = [];
  List<Gasto> _gastos = [];
  PeriodoFiltro _periodo = PeriodoFiltro.dia;
  double _taxaPadraoPercent = HiveService.taxaPadraoDefault;
  String _plataformaPadrao = HiveService.plataformaPadraoDefault;
  PrecosPasseLivre _precosPasseLivre = const PrecosPasseLivre();
  MetaSonho? _metaSonho;
  bool _loading = true;
  String? _uid;
  bool _syncing = false;
  String? _syncError;
  DateTime? _lastSyncAt;
  bool _pruneOnNextSync = false;
  int _authSeq = 0;
  Future<void> _syncChain = Future.value();

  List<Corrida> get corridas => _corridas;
  List<Gasto> get gastos => _gastos;
  PeriodoFiltro get periodo => _periodo;
  double get taxaPadraoPercent => _taxaPadraoPercent;
  String get plataformaPadrao => _plataformaPadrao;
  PrecosPasseLivre get precosPasseLivre => _precosPasseLivre;
  MetaSonho? get metaSonho => _metaSonho;
  bool get loading => _loading;
  bool get cloudSyncAvailable => _syncService.isAvailable;
  bool get cloudSyncEnabled => _uid != null && _syncService.isAvailable;
  bool get syncing => _syncing;
  String? get syncError => _syncError;
  DateTime? get lastSyncAt => _lastSyncAt;

  void attachAuthUid(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _syncError = null;
    _lastSyncAt = HiveService.getLastSyncAt();
    if (uid == null) return;

    final seq = ++_authSeq;
    final owner = HiveService.getDataOwnerUid();
    final switchedAccount = owner != null && owner != uid;
    scheduleMicrotask(
      () => unawaited(
        _enqueueSync(uid: uid, seq: seq, clearLocalFirst: switchedAccount),
      ),
    );
  }

  Future<void> sincronizar() {
    final uid = _uid;
    if (uid == null) return Future.value();
    return _enqueueSync(uid: uid, seq: _authSeq, clearLocalFirst: false);
  }

  Future<void> _enqueueSync({
    required String uid,
    required int seq,
    required bool clearLocalFirst,
  }) {
    _syncChain = _syncChain.catchError((_) {}).then(
      (_) => _runSync(uid: uid, seq: seq, clearLocalFirst: clearLocalFirst),
    );
    return _syncChain;
  }

  Future<void> _runSync({
    required String uid,
    required int seq,
    required bool clearLocalFirst,
  }) async {
    if (seq != _authSeq || _uid != uid || !_syncService.isAvailable) return;

    _syncing = true;
    _syncError = null;
    notifyListeners();
    try {
      if (clearLocalFirst) {
        await HiveService.clearFinanceData();
        await reload();
      }
      await HiveService.setDataOwnerUid(uid);
      if (seq != _authSeq || _uid != uid) return;

      await _syncService.syncAll(uid, pruneRemote: _pruneOnNextSync);
      if (seq != _authSeq || _uid != uid) return;

      _pruneOnNextSync = false;
      await reload();
      _lastSyncAt = HiveService.getLastSyncAt();
    } on CloudSyncException catch (e) {
      if (seq == _authSeq) _syncError = e.message;
    } catch (_) {
      if (seq == _authSeq) {
        _syncError = 'Não foi possível sincronizar. Verifique a internet.';
      }
    } finally {
      if (seq == _authSeq) {
        _syncing = false;
        notifyListeners();
      }
    }
  }

  DateTime _stamp() => DateTime.now().toUtc();

  Future<void> _pushCorrida(Corrida corrida) async {
    final uid = _uid;
    if (uid == null || !_syncService.isAvailable) return;
    try {
      await _syncService.upsertCorrida(uid, corrida);
    } catch (_) {}
  }

  Future<void> _pushGasto(Gasto gasto) async {
    final uid = _uid;
    if (uid == null || !_syncService.isAvailable) return;
    try {
      await _syncService.upsertGasto(uid, gasto);
    } catch (_) {}
  }

  Future<void> _pushSettings() async {
    final uid = _uid;
    if (uid == null || !_syncService.isAvailable) return;
    try {
      await _syncService.upsertSettings(
        uid,
        SettingsSnapshot(
          taxaPadraoPercent: _taxaPadraoPercent,
          plataformaPadrao: _plataformaPadrao,
          precosPasseLivre: _precosPasseLivre,
          metaSonho: _metaSonho,
          updatedAt: HiveService.getSettingsUpdatedAt(),
        ),
      );
    } catch (_) {}
  }

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    _taxaPadraoPercent = HiveService.getTaxaPadraoPercent();
    _plataformaPadrao = HiveService.getPlataformaPadrao();
    _precosPasseLivre = HiveService.getPrecosPasseLivre();
    _metaSonho = HiveService.getMetaSonho();
    _lastSyncAt = HiveService.getLastSyncAt();
    await reload();
    _loading = false;
    notifyListeners();
  }

  Future<void> reload() async {
    _corridas = await _corridaRepo.getAll();
    _gastos = await _gastoRepo.getAll();
    _taxaPadraoPercent = HiveService.getTaxaPadraoPercent();
    _plataformaPadrao = HiveService.getPlataformaPadrao();
    _precosPasseLivre = HiveService.getPrecosPasseLivre();
    _metaSonho = HiveService.getMetaSonho();
    notifyListeners();
  }

  void setPeriodo(PeriodoFiltro periodo) {
    if (_periodo == periodo) return;
    _periodo = periodo;
    notifyListeners();
  }

  Future<void> setTaxaPadraoPercent(double percent) async {
    _taxaPadraoPercent = percent.clamp(0, 100);
    await HiveService.setTaxaPadraoPercent(_taxaPadraoPercent);
    await HiveService.setSettingsUpdatedAt(_stamp());
    await _pushSettings();
    notifyListeners();
  }

  Future<void> setPlataformaPadrao(String plataforma) async {
    _plataformaPadrao = plataforma;
    await HiveService.setPlataformaPadrao(plataforma);
    await HiveService.setSettingsUpdatedAt(_stamp());
    await _pushSettings();
    notifyListeners();
  }

  Future<void> setPrecosPasseLivre(PrecosPasseLivre precos) async {
    _precosPasseLivre = PrecosPasseLivre(
      horas6: precos.horas6.clamp(0, 9999),
      horas12: precos.horas12.clamp(0, 9999),
      horas24: precos.horas24.clamp(0, 9999),
    );
    await HiveService.setPrecosPasseLivre(_precosPasseLivre);
    await HiveService.setSettingsUpdatedAt(_stamp());
    await _pushSettings();
    notifyListeners();
  }

  Future<void> salvarMetaSonho(MetaSonho meta) async {
    final titulo = meta.titulo.trim();
    _metaSonho = MetaSonho(
      titulo: titulo.isEmpty ? 'Meu sonho' : titulo,
      valorAlvo: meta.valorAlvo < 0 ? 0 : meta.valorAlvo,
      valorGuardado: meta.valorGuardado < 0 ? 0 : meta.valorGuardado,
      tipo: meta.tipo,
      criadaEm: meta.criadaEm,
    );
    await HiveService.setMetaSonho(_metaSonho);
    await HiveService.setSettingsUpdatedAt(_stamp());
    await _pushSettings();
    notifyListeners();
  }

  Future<void> guardarNaMeta(double valor) async {
    final atual = _metaSonho;
    if (atual == null || valor <= 0) return;
    await salvarMetaSonho(atual.adicionar(valor));
  }

  Future<void> removerMetaSonho() async {
    _metaSonho = null;
    await HiveService.setMetaSonho(null);
    await HiveService.setSettingsUpdatedAt(_stamp());
    await _pushSettings();
    notifyListeners();
  }

  /// Progresso da meta com previsão pelo lucro médio dos últimos 7 dias.
  ProgressoMeta? progressoMeta([DateTime? ref]) {
    final meta = _metaSonho;
    if (meta == null) return null;
    final now = ref ?? DateTime.now();
    final fim = inicioDoDia(now).add(const Duration(days: 1));
    final inicio = fim.subtract(const Duration(days: 7));
    final lucro = resumoNoIntervalo(inicio, fim).lucroLiquidoReal;
    return ProgressoMeta(meta: meta, lucroMedioDiario: lucro / 7);
  }

  Future<void> adicionarCorrida({
    required double valorBruto,
    required double taxaApp,
    required String formaPagamento,
    String plataforma = '99',
    DateTime? dataHora,
  }) async {
    final corrida = Corrida(
      dataHora: dataHora ?? DateTime.now(),
      valorBruto: valorBruto,
      formaPagamento: formaPagamento,
      taxaApp: taxaApp,
      plataforma: plataforma,
      updatedAt: _stamp(),
    );
    await _corridaRepo.save(corrida);
    await _pushCorrida(corrida);
    await reload();
  }

  Future<void> adicionarGasto({
    required double combustivel,
    required double alimentacao,
    required double outros,
    DateTime? data,
  }) async {
    final gasto = Gasto(
      data: data ?? DateTime.now(),
      combustivel: combustivel,
      alimentacao: alimentacao,
      outros: outros,
      updatedAt: _stamp(),
    );
    await _gastoRepo.save(gasto);
    await _pushGasto(gasto);
    await reload();
  }

  Future<void> atualizarCorrida(Corrida corrida) async {
    final stamped = corrida.copyWith(updatedAt: _stamp());
    await _corridaRepo.save(stamped);
    await _pushCorrida(stamped);
    await reload();
  }

  Future<void> atualizarGasto(Gasto gasto) async {
    final stamped = gasto.copyWith(updatedAt: _stamp());
    await _gastoRepo.save(stamped);
    await _pushGasto(stamped);
    await reload();
  }

  Future<void> excluirCorrida(String id) async {
    await _corridaRepo.delete(id);
    final deletedAt = _stamp();
    await HiveService.addPendingDelete(
      PendingDelete(id: id, type: 'corrida', deletedAt: deletedAt),
    );
    final uid = _uid;
    if (uid != null && _syncService.isAvailable) {
      try {
        await _syncService.tombstoneCorrida(uid, id, deletedAt);
      } catch (_) {}
    }
    await reload();
  }

  Future<void> excluirGasto(String id) async {
    await _gastoRepo.delete(id);
    final deletedAt = _stamp();
    await HiveService.addPendingDelete(
      PendingDelete(id: id, type: 'gasto', deletedAt: deletedAt),
    );
    final uid = _uid;
    if (uid != null && _syncService.isAvailable) {
      try {
        await _syncService.tombstoneGasto(uid, id, deletedAt);
      } catch (_) {}
    }
    await reload();
  }

  /// Gera arquivo JSON de backup e retorna o caminho.
  Future<File> exportBackup() => _backupService.exportToFile();

  /// Restaura a partir de um arquivo JSON e recarrega o estado.
  Future<BackupImportResult> importBackup(
    File file, {
    required BackupRestoreMode mode,
    bool applySettings = true,
  }) async {
    final result = await _backupService.importFromFile(
      file,
      mode: mode,
      applySettings: applySettings,
    );
    if (applySettings) {
      await HiveService.setSettingsUpdatedAt(_stamp());
    }
    if (mode == BackupRestoreMode.replace) {
      _pruneOnNextSync = true;
    }
    await reload();
    unawaited(sincronizar());
    return result;
  }

  ResumoFinanceiro resumoDoPeriodo([PeriodoFiltro? periodo]) {
    final p = periodo ?? _periodo;
    final intervalo = intervaloPeriodo(p);
    return resumoNoIntervalo(intervalo.inicio, intervalo.fim);
  }

  ResumoFinanceiro resumoNoIntervalo(DateTime inicio, DateTime fim) {
    final corridasPeriodo = _corridas.where(
      (c) => estaNoIntervalo(c.dataHora, inicio, fim),
    );

    final gastosPeriodo = _gastos.where(
      (g) => estaNoIntervalo(g.data, inicio, fim),
    );

    double bruto = 0;
    double taxas = 0;
    double liquido = 0;
    var qtd = 0;

    for (final c in corridasPeriodo) {
      bruto += c.valorBruto;
      taxas += c.taxaApp;
      liquido += c.valorLiquido;
      qtd++;
    }

    final totalGastos = gastosPeriodo.fold<double>(
      0,
      (sum, g) => sum + g.total,
    );

    return ResumoFinanceiro(
      totalBruto: bruto,
      totalTaxas: taxas,
      totalLiquidoCorridas: liquido,
      totalGastos: totalGastos,
      quantidadeCorridas: qtd,
    );
  }

  ResumoFinanceiro resumoDoDia(DateTime dia) {
    final inicio = inicioDoDia(dia);
    return resumoNoIntervalo(inicio, inicio.add(const Duration(days: 1)));
  }

  /// Dias do mês com pelo menos uma corrida (dia trabalhado).
  Set<DateTime> diasTrabalhadosNoMes(DateTime mes) {
    final intervalo = intervaloMes(mes);
    final dias = <DateTime>{};
    for (final c in _corridas) {
      if (estaNoIntervalo(c.dataHora, intervalo.inicio, intervalo.fim)) {
        dias.add(inicioDoDia(c.dataHora));
      }
    }
    return dias;
  }

  List<Corrida> corridasDoDia(DateTime dia) {
    final inicio = inicioDoDia(dia);
    final fim = inicio.add(const Duration(days: 1));
    return _corridas
        .where((c) => estaNoIntervalo(c.dataHora, inicio, fim))
        .toList()
      ..sort((a, b) => a.dataHora.compareTo(b.dataHora));
  }

  List<Gasto> gastosDoDia(DateTime dia) {
    final inicio = inicioDoDia(dia);
    final fim = inicio.add(const Duration(days: 1));
    return _gastos
        .where((g) => estaNoIntervalo(g.data, inicio, fim))
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));
  }

  AnalisePasseLivre analisePasseLivreDoDia(DateTime dia) {
    return analisarPasseLivre(
      corridas: corridasDoDia(dia),
      precos: _precosPasseLivre,
    );
  }

  ResumoPasseLivrePeriodo analisePasseLivreDoPeriodo([PeriodoFiltro? periodo]) {
    final intervalo = intervaloPeriodo(periodo ?? _periodo);
    return analisarPasseLivrePorDia(
      corridas: _corridas,
      inicio: intervalo.inicio,
      fim: intervalo.fim,
      precos: _precosPasseLivre,
    );
  }

  /// Ganhos líquidos no período filtrado (índice 0 = mais antigo).
  /// Dia: faixas de 3 horas. Demais: um ponto por dia.
  List<({DateTime inicio, double ganhos})> ganhosDoPeriodo([
    PeriodoFiltro? periodo,
  ]) {
    final p = periodo ?? _periodo;
    final intervalo = intervaloPeriodo(p);

    if (p == PeriodoFiltro.dia) {
      return faixasHorariasDoDia(intervalo.inicio).map((faixa) {
        final total = _corridas
            .where((c) => estaNoIntervalo(c.dataHora, faixa.inicio, faixa.fim))
            .fold<double>(0, (sum, c) => sum + c.valorLiquido);
        return (inicio: faixa.inicio, ganhos: total);
      }).toList();
    }

    return diasNoIntervalo(intervalo.inicio, intervalo.fim).map((dia) {
      final inicio = dia;
      final fim = dia.add(const Duration(days: 1));
      final total = _corridas
          .where((c) => estaNoIntervalo(c.dataHora, inicio, fim))
          .fold<double>(0, (sum, c) => sum + c.valorLiquido);
      return (inicio: inicio, ganhos: total);
    }).toList();
  }

  List<HistoricoItem> get historico {
    final items = <HistoricoItem>[
      ..._corridas.map(HistoricoCorrida.new),
      ..._gastos.map(HistoricoGasto.new),
    ];
    items.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return items;
  }
}
