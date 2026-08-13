import 'package:flutter_test/flutter_test.dart';

import 'package:giropix/core/utils/currency_formatter.dart';
import 'package:giropix/core/utils/date_helpers.dart';
import 'package:giropix/data/models/corrida.dart';
import 'package:giropix/data/models/gasto.dart';

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
}
