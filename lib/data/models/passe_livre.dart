import 'corrida.dart';

/// Preços padrão do passe livre Maxim (moto uniformizado — Araguaína).
class PrecosPasseLivre {
  const PrecosPasseLivre({
    this.horas6 = padrao6h,
    this.horas12 = padrao12h,
    this.horas24 = padrao24h,
  });

  static const double padrao6h = 8.50;
  static const double padrao12h = 17.00;
  static const double padrao24h = 20.50;

  final double horas6;
  final double horas12;
  final double horas24;

  List<PacotePasseLivre> get pacotes => [
        PacotePasseLivre(horas: 6, preco: horas6),
        PacotePasseLivre(horas: 12, preco: horas12),
        PacotePasseLivre(horas: 24, preco: horas24),
      ];

  PrecosPasseLivre copyWith({
    double? horas6,
    double? horas12,
    double? horas24,
  }) {
    return PrecosPasseLivre(
      horas6: horas6 ?? this.horas6,
      horas12: horas12 ?? this.horas12,
      horas24: horas24 ?? this.horas24,
    );
  }
}

class PacotePasseLivre {
  const PacotePasseLivre({required this.horas, required this.preco});

  final int horas;
  final double preco;

  String get label => '$horas horas';
}

class ComparacaoPacote {
  const ComparacaoPacote({
    required this.pacote,
    required this.taxasCobertas,
    required this.totalTaxas,
  });

  final PacotePasseLivre pacote;
  final double taxasCobertas;
  final double totalTaxas;

  double get economia => taxasCobertas - pacote.preco;

  bool get compensaria => economia >= 0.01;

  bool get cobreTudo => (totalTaxas - taxasCobertas).abs() < 0.01;
}

class AnalisePasseLivre {
  const AnalisePasseLivre({
    required this.totalTaxasMaxim,
    required this.quantidadeCorridasMaxim,
    required this.comparacoes,
    this.jornada,
  });

  final double totalTaxasMaxim;
  final int quantidadeCorridasMaxim;
  final Duration? jornada;
  final List<ComparacaoPacote> comparacoes;

  bool get temCorridas => quantidadeCorridasMaxim > 0;

  /// Pacote com maior economia, se algum compensar.
  ComparacaoPacote? get melhor {
    ComparacaoPacote? best;
    for (final c in comparacoes) {
      if (!c.compensaria) continue;
      if (best == null || c.economia > best.economia) best = c;
    }
    return best;
  }
}

class ResumoPasseLivrePeriodo {
  const ResumoPasseLivrePeriodo({
    required this.totalTaxasMaxim,
    required this.quantidadeCorridasMaxim,
    required this.diasComMaxim,
    required this.diasQueCompensariam,
    required this.economiaPotencial,
    required this.analisesPorDia,
  });

  final double totalTaxasMaxim;
  final int quantidadeCorridasMaxim;
  final int diasComMaxim;
  final int diasQueCompensariam;
  final double economiaPotencial;
  final List<({DateTime dia, AnalisePasseLivre analise})> analisesPorDia;

  bool get temCorridas => quantidadeCorridasMaxim > 0;
}

/// Soma as taxas Maxim na melhor janela contínua de [janela].
double taxasNaMelhorJanela(List<Corrida> corridas, Duration janela) {
  if (corridas.isEmpty) return 0;
  final sorted = [...corridas]
    ..sort((a, b) => a.dataHora.compareTo(b.dataHora));

  if (janela >= const Duration(hours: 24)) {
    return sorted.fold<double>(0, (sum, c) => sum + c.taxaApp);
  }

  var maxTaxas = 0.0;
  var j = 0;
  var soma = 0.0;
  for (var i = 0; i < sorted.length; i++) {
    final limite = sorted[i].dataHora.add(janela);
    while (j < sorted.length && !sorted[j].dataHora.isAfter(limite)) {
      soma += sorted[j].taxaApp;
      j++;
    }
    if (soma > maxTaxas) maxTaxas = soma;
    soma -= sorted[i].taxaApp;
  }
  return maxTaxas;
}

AnalisePasseLivre analisarPasseLivre({
  required List<Corrida> corridas,
  PrecosPasseLivre precos = const PrecosPasseLivre(),
}) {
  final maxim = corridas.where((c) => c.isMaxim).toList()
    ..sort((a, b) => a.dataHora.compareTo(b.dataHora));

  final totalTaxas = maxim.fold<double>(0, (sum, c) => sum + c.taxaApp);
  Duration? jornada;
  if (maxim.length >= 2) {
    jornada = maxim.last.dataHora.difference(maxim.first.dataHora);
  }

  final comparacoes = precos.pacotes.map((pacote) {
    final taxas = taxasNaMelhorJanela(
      maxim,
      Duration(hours: pacote.horas),
    );
    return ComparacaoPacote(
      pacote: pacote,
      taxasCobertas: taxas,
      totalTaxas: totalTaxas,
    );
  }).toList();

  return AnalisePasseLivre(
    totalTaxasMaxim: totalTaxas,
    quantidadeCorridasMaxim: maxim.length,
    jornada: jornada,
    comparacoes: comparacoes,
  );
}

ResumoPasseLivrePeriodo analisarPasseLivrePorDia({
  required List<Corrida> corridas,
  required DateTime inicio,
  required DateTime fim,
  PrecosPasseLivre precos = const PrecosPasseLivre(),
}) {
  final maxim = corridas.where((c) {
    if (!c.isMaxim) return false;
    return !c.dataHora.isBefore(inicio) && c.dataHora.isBefore(fim);
  });

  final porDia = <DateTime, List<Corrida>>{};
  for (final c in maxim) {
    final dia = DateTime(c.dataHora.year, c.dataHora.month, c.dataHora.day);
    porDia.putIfAbsent(dia, () => []).add(c);
  }

  final dias = porDia.keys.toList()..sort();
  final analises = <({DateTime dia, AnalisePasseLivre analise})>[];
  var economia = 0.0;
  var diasCompensam = 0;

  for (final dia in dias) {
    final analise = analisarPasseLivre(
      corridas: porDia[dia]!,
      precos: precos,
    );
    analises.add((dia: dia, analise: analise));
    final melhor = analise.melhor;
    if (melhor != null) {
      diasCompensam++;
      economia += melhor.economia;
    }
  }

  final totalTaxas = analises.fold<double>(
    0,
    (sum, item) => sum + item.analise.totalTaxasMaxim,
  );
  final qtd = analises.fold<int>(
    0,
    (sum, item) => sum + item.analise.quantidadeCorridasMaxim,
  );

  return ResumoPasseLivrePeriodo(
    totalTaxasMaxim: totalTaxas,
    quantidadeCorridasMaxim: qtd,
    diasComMaxim: analises.length,
    diasQueCompensariam: diasCompensam,
    economiaPotencial: economia,
    analisesPorDia: analises,
  );
}
