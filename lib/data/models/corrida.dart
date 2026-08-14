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

  /// 99 | iFood | Maxim | Outro. Corridas antigas sem o campo viram Outro.
  @HiveField(5)
  final String plataforma;

  /// Usado na sincronização (último a escrever vence). Ausente em dados antigos.
  @HiveField(6)
  final DateTime? updatedAt;

  Corrida({
    String? id,
    required this.dataHora,
    required this.valorBruto,
    required this.formaPagamento,
    required this.taxaApp,
    this.plataforma = 'Outro',
    this.updatedAt,
  }) : id = id ?? const Uuid().v4();

  DateTime get syncStamp => (updatedAt ?? dataHora).toUtc();

  double get valorLiquido => valorBruto - taxaApp;

  Corrida copyWith({
    String? id,
    DateTime? dataHora,
    double? valorBruto,
    String? formaPagamento,
    double? taxaApp,
    String? plataforma,
    DateTime? updatedAt,
  }) {
    return Corrida(
      id: id ?? this.id,
      dataHora: dataHora ?? this.dataHora,
      valorBruto: valorBruto ?? this.valorBruto,
      formaPagamento: formaPagamento ?? this.formaPagamento,
      taxaApp: taxaApp ?? this.taxaApp,
      plataforma: plataforma ?? this.plataforma,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'dataHora': dataHora.toIso8601String(),
    'valorBruto': valorBruto,
    'formaPagamento': formaPagamento,
    'taxaApp': taxaApp,
    'plataforma': plataforma,
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  factory Corrida.fromJson(Map<String, dynamic> json) {
    return Corrida(
      id: json['id'] as String,
      dataHora: DateTime.parse(json['dataHora'] as String),
      valorBruto: (json['valorBruto'] as num).toDouble(),
      formaPagamento: json['formaPagamento'] as String,
      taxaApp: (json['taxaApp'] as num).toDouble(),
      plataforma: json['plataforma'] as String? ?? 'Outro',
      updatedAt: _parseOptionalDate(json['updatedAt']),
    );
  }
}

DateTime? _parseOptionalDate(dynamic value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
