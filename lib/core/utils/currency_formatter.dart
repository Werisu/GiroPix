import 'package:intl/intl.dart';

final NumberFormat _brl = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);

/// Formata valores em Real brasileiro (BRL).
String formatBrl(double value) => _brl.format(value);

/// Valor para campo de texto (sem símbolo), ex. `15,50`.
String formatInputBrl(double value) =>
    value.toStringAsFixed(2).replaceAll('.', ',');

/// Converte texto de moeda/número BR para double.
/// Aceita "15,50", "15.50", "R$ 15,50", etc.
double? parseBrl(String raw) {
  final cleaned = raw.replaceAll('R\$', '').replaceAll(' ', '').trim();

  if (cleaned.isEmpty) return null;

  // Se tiver vírgula, assume formato BR: 1.234,56
  if (cleaned.contains(',')) {
    final normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  return double.tryParse(cleaned);
}
