/// Faturamento bruto desejado em cada dia da semana.
///
/// A chave é [DateTime.weekday]: 1 = segunda … 7 = domingo.
class MetasDiarias {
  const MetasDiarias({this.valores = const {}});

  static const List<int> semana = [
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];

  final Map<int, double> valores;

  double metaDe(int weekday) {
    final valor = valores[weekday] ?? 0;
    return valor < 0 ? 0 : valor;
  }

  double metaNaData(DateTime data) => metaDe(data.weekday);

  bool get temAlguma => semana.any((dia) => metaDe(dia) > 0);

  MetasDiarias definir(int weekday, double valor) {
    if (!_diaValido(weekday)) return this;
    final next = Map<int, double>.from(valores);
    if (valor <= 0) {
      next.remove(weekday);
    } else {
      next[weekday] = valor;
    }
    return MetasDiarias(valores: Map.unmodifiable(next));
  }

  /// Copia a meta de [origem] para [destinos]. O dia de origem não muda.
  MetasDiarias copiar(int origem, Iterable<int> destinos) {
    if (!_diaValido(origem)) return this;
    final valor = metaDe(origem);
    var atual = this;
    for (final dia in destinos) {
      if (dia == origem) continue;
      atual = atual.definir(dia, valor);
    }
    return atual;
  }

  Map<String, dynamic> toJson() => {
        for (final dia in semana)
          if (metaDe(dia) > 0) dia.toString(): metaDe(dia),
      };

  factory MetasDiarias.fromJson(Map<String, dynamic> json) {
    final raw = json['valores'] is Map ? json['valores'] as Map : json;
    final valores = <int, double>{};
    for (final entry in raw.entries) {
      final dia = int.tryParse(entry.key.toString());
      if (dia == null || !_diaValido(dia)) continue;
      final numero = entry.value;
      if (numero is! num) continue;
      final valor = numero.toDouble();
      if (valor <= 0) continue;
      valores[dia] = valor;
    }
    return MetasDiarias(valores: Map.unmodifiable(valores));
  }

  static bool _diaValido(int weekday) =>
      weekday >= DateTime.monday && weekday <= DateTime.sunday;

  static String nome(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Segunda-feira';
      case DateTime.tuesday:
        return 'Terça-feira';
      case DateTime.wednesday:
        return 'Quarta-feira';
      case DateTime.thursday:
        return 'Quinta-feira';
      case DateTime.friday:
        return 'Sexta-feira';
      case DateTime.saturday:
        return 'Sábado';
      case DateTime.sunday:
        return 'Domingo';
      default:
        return 'Dia';
    }
  }

  static String nomeCurto(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Seg';
      case DateTime.tuesday:
        return 'Ter';
      case DateTime.wednesday:
        return 'Qua';
      case DateTime.thursday:
        return 'Qui';
      case DateTime.friday:
        return 'Sex';
      case DateTime.saturday:
        return 'Sáb';
      case DateTime.sunday:
        return 'Dom';
      default:
        return 'Dia';
    }
  }
}

/// Faturamento bruto do dia comparado com a meta daquele dia da semana.
class ProgressoMetaDiaria {
  const ProgressoMetaDiaria({
    required this.meta,
    required this.realizado,
  });

  final double meta;
  final double realizado;

  bool get definida => meta > 0;

  double get falta {
    final valor = meta - realizado;
    return valor < 0 ? 0 : valor;
  }

  /// 1 = 100%. Pode passar de 1 quando o faturamento supera a meta.
  double get progresso {
    if (meta <= 0) return 0;
    final ratio = realizado / meta;
    return ratio < 0 ? 0 : ratio;
  }

  bool get atingida => definida && realizado >= meta;
}
