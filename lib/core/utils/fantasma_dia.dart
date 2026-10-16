import 'currency_formatter.dart';
import 'date_helpers.dart';

/// O melhor dia anterior com o mesmo dia da semana, comparado até agora.
class FantasmaDia {
  const FantasmaDia({
    required this.weekday,
    required this.ganhosPorFaixa,
    required this.faixaAtual,
    required this.acumuladoFantasma,
    required this.acumuladoHoje,
  });

  final int weekday;

  /// Líquido em cada faixa de 3 horas daquele dia.
  final List<double> ganhosPorFaixa;

  /// Faixa de 3 horas que contém o horário de referência.
  final int faixaAtual;

  final double acumuladoFantasma;
  final double acumuladoHoje;

  bool get naFrente => _centavos(acumuladoHoje) > _centavos(acumuladoFantasma);

  bool get atras => _centavos(acumuladoHoje) < _centavos(acumuladoFantasma);
}

/// Escolhe o dia anterior de mesmo weekday com maior líquido.
/// Empate fica com o mais recente. Sem histórico, devolve null.
FantasmaDia? calcularFantasmaDia({
  required Iterable<({DateTime dataHora, double valorLiquido})> corridas,
  required DateTime agora,
}) {
  final hoje = inicioDoDia(agora);
  final porDia = <DateTime, List<({DateTime dataHora, double valorLiquido})>>{};

  for (final corrida in corridas) {
    final dia = inicioDoDia(corrida.dataHora);
    if (!dia.isBefore(hoje) || dia.weekday != hoje.weekday) continue;
    (porDia[dia] ??= []).add(corrida);
  }
  if (porDia.isEmpty) return null;

  DateTime? melhorDia;
  var melhorTotal = double.negativeInfinity;
  for (final entry in porDia.entries) {
    final total = entry.value.fold<double>(
      0,
      (soma, corrida) => soma + corrida.valorLiquido,
    );
    final substitui =
        melhorDia == null ||
        total > melhorTotal ||
        (total == melhorTotal && entry.key.isAfter(melhorDia));
    if (substitui) {
      melhorDia = entry.key;
      melhorTotal = total;
    }
  }

  final dia = melhorDia!;
  final doDia = porDia[dia]!;
  final faixas = faixasHorariasDoDia(dia);
  final ganhos = [
    for (final faixa in faixas)
      doDia
          .where(
            (corrida) =>
                estaNoIntervalo(corrida.dataHora, faixa.inicio, faixa.fim),
          )
          .fold<double>(0, (soma, corrida) => soma + corrida.valorLiquido),
  ];

  double ateAgora(
    Iterable<({DateTime dataHora, double valorLiquido})> lista,
    DateTime diaBase,
  ) {
    final limite = _segundosNoDia(agora);
    return lista
        .where(
          (corrida) =>
              inicioDoDia(corrida.dataHora) == diaBase &&
              _segundosNoDia(corrida.dataHora) <= limite,
        )
        .fold<double>(0, (soma, corrida) => soma + corrida.valorLiquido);
  }

  final faixa = agora.hour ~/ 3;
  return FantasmaDia(
    weekday: hoje.weekday,
    ganhosPorFaixa: ganhos,
    faixaAtual: faixa >= ganhos.length ? ganhos.length - 1 : faixa,
    acumuladoFantasma: ateAgora(doDia, dia),
    acumuladoHoje: ateAgora(corridas, hoje),
  );
}

String fraseFantasma(FantasmaDia fantasma) {
  final titulo = _titulo(fantasma.weekday);
  final tinha = formatBrl(fantasma.acumuladoFantasma);
  if (fantasma.naFrente) {
    final frente = formatBrl(
      fantasma.acumuladoHoje - fantasma.acumuladoFantasma,
    );
    return '$titulo, agora, tinha $tinha. Você está $frente na frente.';
  }
  if (fantasma.atras) {
    final frente = formatBrl(
      fantasma.acumuladoFantasma - fantasma.acumuladoHoje,
    );
    final pronome = _masculino(fantasma.weekday) ? 'Ele' : 'Ela';
    return '$titulo, agora, tinha $tinha. $pronome está $frente na frente.';
  }
  return '$titulo, agora, também tinha $tinha.';
}

int _centavos(double valor) => (valor * 100).round();

int _segundosNoDia(DateTime instante) =>
    instante.hour * 3600 + instante.minute * 60 + instante.second;

bool _masculino(int weekday) =>
    weekday == DateTime.saturday || weekday == DateTime.sunday;

String _titulo(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'A melhor segunda';
    case DateTime.tuesday:
      return 'A melhor terça';
    case DateTime.wednesday:
      return 'A melhor quarta';
    case DateTime.thursday:
      return 'A melhor quinta';
    case DateTime.friday:
      return 'A melhor sexta';
    case DateTime.saturday:
      return 'O melhor sábado';
    case DateTime.sunday:
      return 'O melhor domingo';
    default:
      return 'O melhor dia';
  }
}
