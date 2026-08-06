/// Períodos do filtro do dashboard.
enum PeriodoFiltro { dia, semana, quinzena, mes }

extension PeriodoFiltroLabel on PeriodoFiltro {
  String get label {
    switch (this) {
      case PeriodoFiltro.dia:
        return 'Dia';
      case PeriodoFiltro.semana:
        return 'Semana';
      case PeriodoFiltro.quinzena:
        return 'Quinzena';
      case PeriodoFiltro.mes:
        return 'Mês';
    }
  }
}

/// Retorna o intervalo [inicio, fim) do período relativo a [ref].
({DateTime inicio, DateTime fim}) intervaloPeriodo(
  PeriodoFiltro periodo, {
  DateTime? ref,
}) {
  final now = ref ?? DateTime.now();
  final hoje = DateTime(now.year, now.month, now.day);
  final amanha = hoje.add(const Duration(days: 1));

  switch (periodo) {
    case PeriodoFiltro.dia:
      return (inicio: hoje, fim: amanha);
    case PeriodoFiltro.semana:
      // Segunda-feira como início da semana
      final weekday = hoje.weekday; // 1=seg ... 7=dom
      final inicioSemana = hoje.subtract(Duration(days: weekday - 1));
      return (inicio: inicioSemana, fim: amanha);
    case PeriodoFiltro.quinzena:
      final dia = hoje.day;
      if (dia <= 15) {
        return (
          inicio: DateTime(hoje.year, hoje.month, 1),
          fim: amanha,
        );
      }
      return (
        inicio: DateTime(hoje.year, hoje.month, 16),
        fim: amanha,
      );
    case PeriodoFiltro.mes:
      return (
        inicio: DateTime(hoje.year, hoje.month, 1),
        fim: amanha,
      );
  }
}

bool estaNoIntervalo(DateTime data, DateTime inicio, DateTime fim) {
  return !data.isBefore(inicio) && data.isBefore(fim);
}

/// Últimos [dias] dias (incluindo hoje), do mais antigo ao mais recente.
List<DateTime> ultimosDias(int dias, {DateTime? ref}) {
  final now = ref ?? DateTime.now();
  final hoje = DateTime(now.year, now.month, now.day);
  return List.generate(
    dias,
    (i) => hoje.subtract(Duration(days: dias - 1 - i)),
  );
}

DateTime inicioDoDia(DateTime d) => DateTime(d.year, d.month, d.day);
