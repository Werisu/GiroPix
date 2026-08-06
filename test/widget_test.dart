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
    );
    final restored = Corrida.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.valorBruto, original.valorBruto);
    expect(restored.formaPagamento, original.formaPagamento);
    expect(restored.taxaApp, original.taxaApp);
    expect(restored.dataHora, original.dataHora);
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

