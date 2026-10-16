/// Faturamento bruto desejado em cada dia da semana.
///
/// A chave é [DateTime.weekday]: 1 = segunda … 7 = domingo.
/// Semana, quinzena e mês não são editados: saem da soma desses dias.
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

  /// Soma a meta de cada dia em [inicio, fim).
  double somaEntre(DateTime inicio, DateTime fim) {
    final start = _dia(inicio);
    final end = _dia(fim);
    var total = 0.0;
    var cursor = start;
    while (cursor.isBefore(end)) {
      total += metaNaData(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return total;
  }

  /// Segunda a domingo da semana que contém [ref].
  double metaDaSemana(DateTime ref) {
    final hoje = _dia(ref);
    final inicio = hoje.subtract(Duration(days: hoje.weekday - 1));
    return somaEntre(inicio, inicio.add(const Duration(days: 7)));
  }

  /// Quinzena civil que contém [ref]: dias 1–15 ou 16 até o fim do mês.
  double metaDaQuinzena(DateTime ref) {
    final hoje = _dia(ref);
    if (hoje.day <= 15) {
      return somaEntre(
        DateTime(hoje.year, hoje.month, 1),
        DateTime(hoje.year, hoje.month, 16),
      );
    }
    return somaEntre(
      DateTime(hoje.year, hoje.month, 16),
      DateTime(hoje.year, hoje.month + 1, 1),
    );
  }

  /// Todos os dias do mês civil de [ref].
  double metaDoMes(DateTime ref) {
    final hoje = _dia(ref);
    return somaEntre(
      DateTime(hoje.year, hoje.month, 1),
      DateTime(hoje.year, hoje.month + 1, 1),
    );
  }

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

  static DateTime _dia(DateTime data) =>
      DateTime(data.year, data.month, data.day);

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

/// Faturamento bruto comparado com a meta de um período.
class AlvoMeta {
  const AlvoMeta({
    required this.titulo,
    required this.detalhe,
    required this.meta,
    required this.realizado,
  });

  final String titulo;
  final String detalhe;
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

  /// Verdadeiro só quando este resultado cruza a meta e [antes] ainda não tinha.
  bool cruzouAgora(AlvoMeta antes) => !antes.atingida && atingida;
}
