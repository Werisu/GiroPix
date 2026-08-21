import 'package:flutter_test/flutter_test.dart';

import 'package:giropix/core/utils/currency_formatter.dart';
import 'package:giropix/core/utils/date_helpers.dart';
import 'package:giropix/data/models/corrida.dart';
import 'package:giropix/data/models/gasto.dart';
import 'package:giropix/data/models/meta_sonho.dart';
import 'package:giropix/data/models/passe_livre.dart';
import 'package:giropix/data/services/sync_merger.dart';

void main() {
  test('valorLiquido calcula bruto menos taxa', () {
    final corrida = Corrida(
      dataHora: DateTime(2026, 8, 5, 12),
      valorBruto: 100,
      formaPagamento: 'Pix',
      taxaApp: 15,
    );
    expect(corrida.valorLiquido, 85);
  });

  test('gasto.total soma categorias', () {
    final gasto = Gasto(
      data: DateTime(2026, 8, 5),
      combustivel: 40,
      alimentacao: 25,
      outros: 10,
    );
    expect(gasto.total, 75);
  });

  test('parseBrl aceita formato brasileiro', () {
    expect(parseBrl('15,50'), 15.5);
    expect(parseBrl('R\$ 1.234,56'), 1234.56);
  });

  test('formatInputBrl usa vírgula decimal', () {
    expect(formatInputBrl(15.5), '15,50');
    expect(formatInputBrl(1234.56), '1234,56');
  });

  test('Corrida.copyWith preserva o id', () {
    final original = Corrida(
      id: 'c1',
      dataHora: DateTime(2026, 8, 5, 12),
      valorBruto: 40,
      formaPagamento: 'Pix',
      taxaApp: 6,
    );
    final edited = original.copyWith(
      valorBruto: 50,
      dataHora: DateTime(2026, 8, 4, 10),
    );
    expect(edited.id, 'c1');
    expect(edited.valorBruto, 50);
    expect(edited.taxaApp, 6);
  });

  test('intervaloPeriodo dia cobre apenas o dia atual', () {
    final ref = DateTime(2026, 8, 5, 15, 30);
    final intervalo = intervaloPeriodo(PeriodoFiltro.dia, ref: ref);
    expect(intervalo.inicio, DateTime(2026, 8, 5));
    expect(intervalo.fim, DateTime(2026, 8, 6));
  });

  test('Corrida toJson/fromJson roundtrip', () {
    final original = Corrida(
      id: 'c1',
      dataHora: DateTime(2026, 8, 5, 12),
      valorBruto: 40,
      formaPagamento: 'Pix',
      taxaApp: 6,
      plataforma: 'iFood',
    );
    final restored = Corrida.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.valorBruto, original.valorBruto);
    expect(restored.formaPagamento, original.formaPagamento);
    expect(restored.taxaApp, original.taxaApp);
    expect(restored.dataHora, original.dataHora);
    expect(restored.plataforma, 'iFood');
  });

  test('Corrida.fromJson sem plataforma assume Outro', () {
    final restored = Corrida.fromJson({
      'id': 'c2',
      'dataHora': '2026-08-05T12:00:00.000',
      'valorBruto': 20,
      'formaPagamento': 'Dinheiro',
      'taxaApp': 0,
    });
    expect(restored.plataforma, 'Outro');
  });

  test('intervaloMes cobre o mês civil inteiro', () {
    final intervalo = intervaloMes(DateTime(2026, 8, 13, 18));
    expect(intervalo.inicio, DateTime(2026, 8, 1));
    expect(intervalo.fim, DateTime(2026, 9, 1));
  });

  test('offsetCalendarioDomingo alinha o dia 1 na grade', () {
    // 1º ago 2026 foi sábado (weekday=6) → 6 células vazias antes.
    expect(offsetCalendarioDomingo(DateTime(2026, 8, 1)), 6);
    // 1º mar 2026 foi domingo (weekday=7) → sem offset.
    expect(offsetCalendarioDomingo(DateTime(2026, 3, 1)), 0);
  });

  test('diasNoIntervalo lista dias em [inicio, fim)', () {
    final dias = diasNoIntervalo(DateTime(2026, 8, 1), DateTime(2026, 8, 4));
    expect(dias, [
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 2),
      DateTime(2026, 8, 3),
    ]);
  });

  test('faixasHorariasDoDia cobre 24h em blocos de 3h', () {
    final faixas = faixasHorariasDoDia(DateTime(2026, 8, 5, 15));
    expect(faixas.length, 8);
    expect(faixas.first.inicio, DateTime(2026, 8, 5));
    expect(faixas.last.inicio, DateTime(2026, 8, 5, 21));
    expect(faixas.last.fim, DateTime(2026, 8, 6));
  });

  test('Corrida.fromJson lê updatedAt quando presente', () {
    final restored = Corrida.fromJson({
      'id': 'c3',
      'dataHora': '2026-08-05T12:00:00.000',
      'valorBruto': 20,
      'formaPagamento': 'Pix',
      'taxaApp': 2,
      'updatedAt': '2026-08-05T15:00:00.000Z',
    });
    expect(restored.updatedAt, DateTime.parse('2026-08-05T15:00:00.000Z'));
  });

  test('merge prioriza o updatedAt mais recente', () {
    final local = Corrida(
      id: 'c1',
      dataHora: DateTime.utc(2026, 8, 1, 10),
      valorBruto: 40,
      formaPagamento: 'Pix',
      taxaApp: 6,
      updatedAt: DateTime.utc(2026, 8, 1, 10),
    );
    final remoteItem = local.copyWith(
      valorBruto: 80,
      updatedAt: DateTime.utc(2026, 8, 2, 10),
    );
    final merged = SyncMerger.mergeCorridas(
      local: [local],
      remote: [
        CloudRecord(
          id: 'c1',
          deleted: false,
          updatedAt: remoteItem.syncStamp,
          item: remoteItem,
        ),
      ],
      pendingDeletes: const [],
    );
    expect(merged.single.valorBruto, 80);
  });

  test('merge aplica tombstone e remove o lançamento local', () {
    final local = Corrida(
      id: 'c1',
      dataHora: DateTime.utc(2026, 8, 1, 10),
      valorBruto: 40,
      formaPagamento: 'Pix',
      taxaApp: 6,
      updatedAt: DateTime.utc(2026, 8, 1, 10),
    );
    final merged = SyncMerger.mergeCorridas(
      local: [local],
      remote: [
        CloudRecord(
          id: 'c1',
          deleted: true,
          updatedAt: DateTime.utc(2026, 8, 1, 12),
        ),
      ],
      pendingDeletes: const [],
    );
    expect(merged, isEmpty);
  });

  test('merge mantém item só local e ignora tombstone mais antigo', () {
    final local = Gasto(
      id: 'g1',
      data: DateTime.utc(2026, 8, 1, 18),
      combustivel: 30,
      updatedAt: DateTime.utc(2026, 8, 2, 10),
    );
    final merged = SyncMerger.mergeGastos(
      local: [local],
      remote: const [],
      pendingDeletes: [
        PendingDelete(
          id: 'g1',
          type: 'gasto',
          deletedAt: DateTime.utc(2026, 8, 1, 12),
        ),
      ],
    );
    expect(merged.single.id, 'g1');
  });

  test('belongsToUser ignora documento de outra conta', () {
    expect(SyncMerger.belongsToUser(null, 'uid-a'), isTrue);
    expect(SyncMerger.belongsToUser('', 'uid-a'), isTrue);
    expect(SyncMerger.belongsToUser('uid-a', 'uid-a'), isTrue);
    expect(SyncMerger.belongsToUser('uid-b', 'uid-a'), isFalse);
  });

  test('merge descarta registro marcado como de outra conta', () {
    final local = Corrida(
      id: 'c1',
      dataHora: DateTime.utc(2026, 8, 1, 10),
      valorBruto: 40,
      formaPagamento: 'Pix',
      taxaApp: 6,
      updatedAt: DateTime.utc(2026, 8, 1, 10),
    );
    final merged = SyncMerger.mergeCorridas(
      local: [local],
      remote: [
        CloudRecord(
          id: 'c1',
          deleted: false,
          foreign: true,
          updatedAt: DateTime.utc(2026, 8, 1, 12),
        ),
      ],
      pendingDeletes: const [],
    );
    expect(merged, isEmpty);
  });

  test('Gasto toJson/fromJson roundtrip', () {
    final original = Gasto(
      id: 'g1',
      data: DateTime(2026, 8, 5, 18),
      combustivel: 30,
      alimentacao: 15,
      outros: 5,
    );
    final restored = Gasto.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.total, 50);
  });

  test('Corrida.isMaxim inclui Maxim e Uber antigo', () {
    final maxim = Corrida(
      dataHora: DateTime(2026, 8, 17, 10),
      valorBruto: 20,
      formaPagamento: 'Pix',
      taxaApp: 3,
      plataforma: 'Maxim',
    );
    final uber = maxim.copyWith(plataforma: 'Uber');
    final ifood = maxim.copyWith(plataforma: 'iFood');
    expect(maxim.isMaxim, isTrue);
    expect(uber.isMaxim, isTrue);
    expect(ifood.isMaxim, isFalse);
  });

  test('passe 24h compensaria quando a taxa do dia passa do preço', () {
    final corridas = [
      Corrida(
        dataHora: DateTime(2026, 8, 17, 8),
        valorBruto: 80,
        formaPagamento: 'Pix',
        taxaApp: 12,
        plataforma: 'Maxim',
      ),
      Corrida(
        dataHora: DateTime(2026, 8, 17, 18),
        valorBruto: 70,
        formaPagamento: 'Pix',
        taxaApp: 10.5,
        plataforma: 'Maxim',
      ),
    ];
    final analise = analisarPasseLivre(corridas: corridas);
    expect(analise.totalTaxasMaxim, 22.5);
    final p24 = analise.comparacoes.singleWhere((c) => c.pacote.horas == 24);
    expect(p24.cobreTudo, isTrue);
    expect(p24.compensaria, isTrue);
    expect(p24.economia, closeTo(2.0, 0.001));
    expect(analise.melhor?.pacote.horas, 12);
  });

  test('passe não compensaria se a taxa do dia for menor que o pacote', () {
    final corridas = [
      Corrida(
        dataHora: DateTime(2026, 8, 17, 10),
        valorBruto: 30,
        formaPagamento: 'Pix',
        taxaApp: 4,
        plataforma: 'Maxim',
      ),
    ];
    final analise = analisarPasseLivre(corridas: corridas);
    expect(analise.melhor, isNull);
    for (final c in analise.comparacoes) {
      expect(c.compensaria, isFalse);
    }
  });

  test('janela de 6h pega o trecho com mais taxa, não o dia inteiro', () {
    final corridas = [
      Corrida(
        dataHora: DateTime(2026, 8, 17, 7),
        valorBruto: 20,
        formaPagamento: 'Pix',
        taxaApp: 3,
        plataforma: 'Maxim',
      ),
      Corrida(
        dataHora: DateTime(2026, 8, 17, 12),
        valorBruto: 50,
        formaPagamento: 'Pix',
        taxaApp: 10,
        plataforma: 'Maxim',
      ),
      Corrida(
        dataHora: DateTime(2026, 8, 17, 14),
        valorBruto: 40,
        formaPagamento: 'Pix',
        taxaApp: 8,
        plataforma: 'Maxim',
      ),
    ];
    final analise = analisarPasseLivre(corridas: corridas);
    final p6 = analise.comparacoes.singleWhere((c) => c.pacote.horas == 6);
    expect(p6.taxasCobertas, 18);
    expect(p6.cobreTudo, isFalse);
    expect(p6.compensaria, isTrue);
    expect(p6.economia, closeTo(9.5, 0.001));
  });

  test('análise do período ignora apps que não são Maxim', () {
    final corridas = [
      Corrida(
        dataHora: DateTime(2026, 8, 17, 10),
        valorBruto: 40,
        formaPagamento: 'Pix',
        taxaApp: 6,
        plataforma: 'Maxim',
      ),
      Corrida(
        dataHora: DateTime(2026, 8, 17, 11),
        valorBruto: 40,
        formaPagamento: 'Pix',
        taxaApp: 8,
        plataforma: '99',
      ),
      Corrida(
        dataHora: DateTime(2026, 8, 18, 10),
        valorBruto: 20,
        formaPagamento: 'Pix',
        taxaApp: 3,
        plataforma: 'Maxim',
      ),
    ];
    final resumo = analisarPasseLivrePorDia(
      corridas: corridas,
      inicio: DateTime(2026, 8, 17),
      fim: DateTime(2026, 8, 19),
    );
    expect(resumo.totalTaxasMaxim, 9);
    expect(resumo.diasComMaxim, 2);
    expect(resumo.diasQueCompensariam, 0);
    expect(resumo.quantidadeCorridasMaxim, 2);
  });

  test('MetaSonho toJson/fromJson roundtrip', () {
    final original = MetaSonho(
      titulo: 'Moto esportiva',
      valorAlvo: 18000,
      valorGuardado: 2500,
      tipo: TipoMeta.moto,
      criadaEm: DateTime.utc(2026, 8, 20, 12),
    );
    final restored = MetaSonho.fromJson(original.toJson());
    expect(restored.titulo, 'Moto esportiva');
    expect(restored.valorAlvo, 18000);
    expect(restored.valorGuardado, 2500);
    expect(restored.tipo, TipoMeta.moto);
    expect(restored.criadaEm, DateTime.utc(2026, 8, 20, 12));
  });

  test('MetaSonho calcula progresso, restante e conquista', () {
    final meta = MetaSonho(
      titulo: 'Moto esportiva',
      valorAlvo: 10000,
      valorGuardado: 2500,
      criadaEm: DateTime.utc(2026, 1, 1),
    );
    expect(meta.progresso, closeTo(0.25, 0.0001));
    expect(meta.restante, 7500);
    expect(meta.conquistada, isFalse);
    expect(meta.adicionar(8000).conquistada, isTrue);
  });

  test('ProgressoMeta estima dias pelo lucro médio', () {
    final meta = MetaSonho(
      titulo: 'Moto esportiva',
      valorAlvo: 1000,
      valorGuardado: 200,
      criadaEm: DateTime.utc(2026, 1, 1),
    );
    final progresso = ProgressoMeta(meta: meta, lucroMedioDiario: 80);
    expect(progresso.diasEstimados, 10);
    expect(progresso.previsaoTexto(), contains('10 dias'));
  });

  test('mergeSettings preserva meta local se a nuvem ainda não tem o campo', () {
    final localMeta = MetaSonho(
      titulo: 'Moto esportiva',
      valorAlvo: 18000,
      valorGuardado: 500,
      criadaEm: DateTime.utc(2026, 8, 1),
    );
    final local = SettingsSnapshot(
      taxaPadraoPercent: 15,
      plataformaPadrao: '99',
      updatedAt: DateTime.utc(2026, 8, 1),
      metaSonho: localMeta,
    );
    final remote = SettingsSnapshot(
      taxaPadraoPercent: 20,
      plataformaPadrao: 'Maxim',
      updatedAt: DateTime.utc(2026, 8, 10),
      metaSonhoDefined: false,
    );
    final merged = SyncMerger.mergeSettings(local: local, remote: remote);
    expect(merged.taxaPadraoPercent, 20);
    expect(merged.plataformaPadrao, 'Maxim');
    expect(merged.metaSonho?.titulo, 'Moto esportiva');
  });

  test('mergeSettings aceita remoção explícita da meta na nuvem', () {
    final local = SettingsSnapshot(
      taxaPadraoPercent: 15,
      plataformaPadrao: '99',
      updatedAt: DateTime.utc(2026, 8, 1),
      metaSonho: MetaSonho(
        titulo: 'Moto esportiva',
        valorAlvo: 18000,
        criadaEm: DateTime.utc(2026, 8, 1),
      ),
    );
    final remote = SettingsSnapshot(
      taxaPadraoPercent: 15,
      plataformaPadrao: '99',
      updatedAt: DateTime.utc(2026, 8, 10),
      metaSonho: null,
    );
    final merged = SyncMerger.mergeSettings(local: local, remote: remote);
    expect(merged.metaSonho, isNull);
  });
}
