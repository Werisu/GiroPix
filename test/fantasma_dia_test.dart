import 'package:flutter_test/flutter_test.dart';
import 'package:giropix/core/utils/currency_formatter.dart';
import 'package:giropix/core/utils/fantasma_dia.dart';

typedef _Corrida = ({DateTime dataHora, double valorLiquido});

_Corrida _c(DateTime dataHora, double liquido) =>
    (dataHora: dataHora, valorLiquido: liquido);

void main() {
  test(
    'fantasma é o mesmo weekday com maior líquido, até o horário de agora',
    () {
      final agora = DateTime(2026, 10, 16, 15, 30);
      final fantasma = calcularFantasmaDia(
        agora: agora,
        corridas: [
          _c(DateTime(2026, 10, 2, 11), 80),
          _c(DateTime(2026, 10, 2, 14), 40),
          _c(DateTime(2026, 10, 9, 10), 50),
          _c(DateTime(2026, 10, 9, 18), 200),
          _c(DateTime(2026, 10, 15, 12), 999),
          _c(DateTime(2026, 10, 16, 12), 90),
          _c(DateTime(2026, 10, 16, 20), 70),
        ],
      );

      expect(fantasma, isNotNull);
      expect(fantasma!.weekday, DateTime.friday);
      expect(fantasma.faixaAtual, 5);
      expect(fantasma.ganhosPorFaixa, [0, 0, 0, 50, 0, 0, 200, 0]);
      expect(fantasma.acumuladoFantasma, 50);
      expect(fantasma.acumuladoHoje, 90);
      expect(fantasma.naFrente, isTrue);
      expect(
        fraseFantasma(fantasma),
        'A melhor sexta, agora, tinha ${formatBrl(50)}. '
        'Você está ${formatBrl(40)} na frente.',
      );
    },
  );

  test('empate de líquido fica com o dia mais recente', () {
    final fantasma = calcularFantasmaDia(
      agora: DateTime(2026, 10, 16, 12),
      corridas: [
        _c(DateTime(2026, 10, 2, 8), 60),
        _c(DateTime(2026, 10, 2, 20), 40),
        _c(DateTime(2026, 10, 9, 9), 100),
      ],
    );

    expect(fantasma!.ganhosPorFaixa[2], 0);
    expect(fantasma.ganhosPorFaixa[3], 100);
    expect(fantasma.acumuladoFantasma, 100);
  });

  test('sem outro dia igual não há fantasma', () {
    final fantasma = calcularFantasmaDia(
      agora: DateTime(2026, 10, 16, 12),
      corridas: [_c(DateTime(2026, 10, 16, 10), 40)],
    );
    expect(fantasma, isNull);
  });

  test('sábado atrás usa pronome masculino', () {
    final fantasma = calcularFantasmaDia(
      agora: DateTime(2026, 10, 17, 11),
      corridas: [
        _c(DateTime(2026, 10, 10, 10), 80),
        _c(DateTime(2026, 10, 17, 10), 30),
      ],
    );

    expect(fantasma!.atras, isTrue);
    expect(
      fraseFantasma(fantasma),
      'O melhor sábado, agora, tinha ${formatBrl(80)}. '
      'Ele está ${formatBrl(50)} na frente.',
    );
  });

  test('placar empatado', () {
    final fantasma = calcularFantasmaDia(
      agora: DateTime(2026, 10, 18, 16),
      corridas: [
        _c(DateTime(2026, 10, 11, 15), 40),
        _c(DateTime(2026, 10, 18, 15), 40),
      ],
    );

    expect(fantasma!.naFrente, isFalse);
    expect(fantasma.atras, isFalse);
    expect(
      fraseFantasma(fantasma),
      'O melhor domingo, agora, também tinha ${formatBrl(40)}.',
    );
  });
}
