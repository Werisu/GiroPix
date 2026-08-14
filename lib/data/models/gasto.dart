import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'gasto.g.dart';

@HiveType(typeId: 1)
class Gasto extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime data;

  @HiveField(2)
  final double combustivel;

  @HiveField(3)
  final double alimentacao;

  @HiveField(4)
  final double outros;

  @HiveField(5)
  final DateTime? updatedAt;

  Gasto({
    String? id,
    required this.data,
    this.combustivel = 0,
    this.alimentacao = 0,
    this.outros = 0,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4();

  DateTime get syncStamp => (updatedAt ?? data).toUtc();

  double get total => combustivel + alimentacao + outros;

  Gasto copyWith({
    String? id,
    DateTime? data,
    double? combustivel,
    double? alimentacao,
    double? outros,
    DateTime? updatedAt,
  }) {
    return Gasto(
      id: id ?? this.id,
      data: data ?? this.data,
      combustivel: combustivel ?? this.combustivel,
      alimentacao: alimentacao ?? this.alimentacao,
      outros: outros ?? this.outros,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data.toIso8601String(),
        'combustivel': combustivel,
        'alimentacao': alimentacao,
        'outros': outros,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  factory Gasto.fromJson(Map<String, dynamic> json) {
    return Gasto(
      id: json['id'] as String,
      data: DateTime.parse(json['data'] as String),
      combustivel: (json['combustivel'] as num?)?.toDouble() ?? 0,
      alimentacao: (json['alimentacao'] as num?)?.toDouble() ?? 0,
      outros: (json['outros'] as num?)?.toDouble() ?? 0,
      updatedAt: _parseOptionalDate(json['updatedAt']),
    );
  }
}

DateTime? _parseOptionalDate(dynamic value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
