class ResumoFinanceiro {
  final double totalBruto;
  final double totalTaxas;
  final double totalLiquidoCorridas;
  final double totalGastos;
  final int quantidadeCorridas;

  const ResumoFinanceiro({
    this.totalBruto = 0,
    this.totalTaxas = 0,
    this.totalLiquidoCorridas = 0,
    this.totalGastos = 0,
    this.quantidadeCorridas = 0,
  });

  /// Lucro líquido real = líquido das corridas − gastos.
  double get lucroLiquidoReal => totalLiquidoCorridas - totalGastos;
}
