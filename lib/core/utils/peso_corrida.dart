/// Quantidade mínima de corridas anteriores para a média servir de referência.
const int minimoCorridasParaPeso = 3;

/// Corrida grande: o bruto passa da média das corridas anteriores.
///
/// Com menos de [minimoCorridasParaPeso] valores positivos, devolve falso.
/// O próprio lançamento não entra na média.
bool corridaPesada(double valorBruto, Iterable<double> anteriores) {
  if (valorBruto <= 0) return false;
  final amostras = [
    for (final valor in anteriores)
      if (valor > 0) valor,
  ];
  if (amostras.length < minimoCorridasParaPeso) return false;
  final media = amostras.reduce((a, b) => a + b) / amostras.length;
  return valorBruto > media;
}
