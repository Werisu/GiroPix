import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'corrida.g.dart';

@HiveType(typeId: 0)
class Corrida extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime dataHora;

  @HiveField(2)
  final double valorBruto;

  @HiveField(3)
  final String formaPagamento; // Pix | Dinheiro | Cartão

  @HiveField(4)
  final double taxaApp;

  Corrida({
    String? id,
    required this.dataHora,
    required this.valorBruto,
    required this.formaPagamento,
    required this.taxaApp,
  }) : id = id ?? const Uuid().v4();

  double get valorLiquido => valorBruto - taxaApp;

  Corrida copyWith({
    String? id,
    DateTime? dataHora,
    double? valorBruto,
    String? formaPagamento,
    double? taxaApp,
  }) {
    return Corrida(
      id: id ?? this.id,
      dataHora: dataHora ?? this.dataHora,
      valorBruto: valorBruto ?? this.valorBruto,
      formaPagamento: formaPagamento ?? this.formaPagamento,
      taxaApp: taxaApp ?? this.taxaApp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dataHora': dataHora.toIso8601String(),
        'valorBruto': valorBruto,
        'formaPagamento': formaPagamento,
        'taxaApp': taxaApp,
      };

  factory Corrida.fromJson(Map<String, dynamic> json) {
    return Corrida(
      id: json['id'] as String,
      dataHora: DateTime.parse(json['dataHora'] as String),
      valorBruto: (json['valorBruto'] as num).toDouble(),
      formaPagamento: json['formaPagamento'] as String,
      taxaApp: (json['taxaApp'] as num).toDouble(),
    );
  }
}
