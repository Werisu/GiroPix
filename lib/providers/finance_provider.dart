import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/utils/date_helpers.dart';
import '../data/local/hive_service.dart';
import '../data/models/corrida.dart';
import '../data/models/gasto.dart';
import '../data/models/resumo_financeiro.dart';
import '../data/repositories/corrida_repository.dart';
import '../data/repositories/gasto_repository.dart';
import '../data/services/backup_service.dart';

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
  }) : _corridaRepo = corridaRepository ?? CorridaRepository(),
       _gastoRepo = gastoRepository ?? GastoRepository(),
       _backupService = backupService ?? BackupService();

  final CorridaRepository _corridaRepo;
  final GastoRepository _gastoRepo;
  final BackupService _backupService;

  List<Corrida> _corridas = [];
  List<Gasto> _gastos = [];
  PeriodoFiltro _periodo = PeriodoFiltro.dia;
  double _taxaPadraoPercent = HiveService.taxaPadraoDefault;
  String _plataformaPadrao = HiveService.plataformaPadraoDefault;
  bool _loading = true;

  List<Corrida> get corridas => _corridas;
  List<Gasto> get gastos => _gastos;
  PeriodoFiltro get periodo => _periodo;
  double get taxaPadraoPercent => _taxaPadraoPercent;
  String get plataformaPadrao => _plataformaPadrao;
  bool get loading => _loading;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    _taxaPadraoPercent = HiveService.getTaxaPadraoPercent();
    _plataformaPadrao = HiveService.getPlataformaPadrao();
    await reload();
    _loading = false;
    notifyListeners();
  }

  Future<void> reload() async {
    _corridas = await _corridaRepo.getAll();
    _gastos = await _gastoRepo.getAll();
    _taxaPadraoPercent = HiveService.getTaxaPadraoPercent();
    _plataformaPadrao = HiveService.getPlataformaPadrao();
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
    notifyListeners();
  }

  Future<void> setPlataformaPadrao(String plataforma) async {
    _plataformaPadrao = plataforma;
    await HiveService.setPlataformaPadrao(plataforma);
    notifyListeners();
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
    );
    await _corridaRepo.save(corrida);
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
    );
    await _gastoRepo.save(gasto);
    await reload();
  }

  Future<void> atualizarCorrida(Corrida corrida) async {
    await _corridaRepo.save(corrida);
    await reload();
  }

  Future<void> atualizarGasto(Gasto gasto) async {
    await _gastoRepo.save(gasto);
    await reload();
  }

  Future<void> excluirCorrida(String id) async {
    await _corridaRepo.delete(id);
    await reload();
  }

  Future<void> excluirGasto(String id) async {
    await _gastoRepo.delete(id);
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
    await reload();
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
