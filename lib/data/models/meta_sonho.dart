import 'package:flutter/material.dart';

/// Tipo visual da meta — só muda o ícone.
enum TipoMeta {
  moto,
  carro,
  casa,
  viagem,
  outro,
}

extension TipoMetaUi on TipoMeta {
  String get label {
    switch (this) {
      case TipoMeta.moto:
        return 'Moto';
      case TipoMeta.carro:
        return 'Carro';
      case TipoMeta.casa:
        return 'Casa';
      case TipoMeta.viagem:
        return 'Viagem';
      case TipoMeta.outro:
        return 'Outro';
    }
  }

  IconData get icon {
    switch (this) {
      case TipoMeta.moto:
        return Icons.two_wheeler_rounded;
      case TipoMeta.carro:
        return Icons.directions_car_rounded;
      case TipoMeta.casa:
        return Icons.home_rounded;
      case TipoMeta.viagem:
        return Icons.flight_takeoff_rounded;
      case TipoMeta.outro:
        return Icons.flag_rounded;
    }
  }

  static TipoMeta fromId(String? id) {
    for (final tipo in TipoMeta.values) {
      if (tipo.name == id) return tipo;
    }
    return TipoMeta.moto;
  }
}

/// Sonho único que o motoboy quer conquistar (ex.: moto esportiva).
class MetaSonho {
  const MetaSonho({
    required this.titulo,
    required this.valorAlvo,
    this.valorGuardado = 0,
    this.tipo = TipoMeta.moto,
    required this.criadaEm,
  });

  final String titulo;
  final double valorAlvo;
  final double valorGuardado;
  final TipoMeta tipo;
  final DateTime criadaEm;

  double get restante {
    final falta = valorAlvo - valorGuardado;
    return falta < 0 ? 0 : falta;
  }

  double get progresso {
    if (valorAlvo <= 0) return 0;
    final ratio = valorGuardado / valorAlvo;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
  }

  bool get conquistada => valorAlvo > 0 && valorGuardado >= valorAlvo;

  MetaSonho copyWith({
    String? titulo,
    double? valorAlvo,
    double? valorGuardado,
    TipoMeta? tipo,
    DateTime? criadaEm,
  }) {
    return MetaSonho(
      titulo: titulo ?? this.titulo,
      valorAlvo: valorAlvo ?? this.valorAlvo,
      valorGuardado: valorGuardado ?? this.valorGuardado,
      tipo: tipo ?? this.tipo,
      criadaEm: criadaEm ?? this.criadaEm,
    );
  }

  MetaSonho adicionar(double valor) {
    final novo = valorGuardado + valor;
    return copyWith(valorGuardado: novo < 0 ? 0 : novo);
  }

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'valorAlvo': valorAlvo,
        'valorGuardado': valorGuardado,
        'tipo': tipo.name,
        'criadaEm': criadaEm.toUtc().toIso8601String(),
      };

  factory MetaSonho.fromJson(Map<String, dynamic> json) {
    final titulo = (json['titulo'] as String?)?.trim() ?? '';
    final alvo = (json['valorAlvo'] as num?)?.toDouble() ?? 0;
    final guardado = (json['valorGuardado'] as num?)?.toDouble() ?? 0;
    return MetaSonho(
      titulo: titulo.isEmpty ? 'Meu sonho' : titulo,
      valorAlvo: alvo < 0 ? 0 : alvo,
      valorGuardado: guardado < 0 ? 0 : guardado,
      tipo: TipoMetaUi.fromId(json['tipo'] as String?),
      criadaEm: DateTime.tryParse(json['criadaEm'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Progresso da meta com previsão baseada no lucro recente.
class ProgressoMeta {
  const ProgressoMeta({
    required this.meta,
    required this.lucroMedioDiario,
  });

  final MetaSonho meta;
  final double lucroMedioDiario;

  /// Dias até a meta se guardar o lucro médio diário recente.
  int? get diasEstimados {
    if (meta.conquistada) return 0;
    if (lucroMedioDiario <= 0.01) return null;
    return (meta.restante / lucroMedioDiario).ceil();
  }

  String previsaoTexto() {
    if (meta.conquistada) return 'Sonho conquistado!';
    final dias = diasEstimados;
    if (dias == null) {
      return 'Lance mais corridas para estimar quando você chega lá.';
    }
    if (dias <= 1) return 'No ritmo atual, chega amanhã.';
    if (dias < 30) return 'No ritmo atual, chega em $dias dias.';
    if (dias < 365) {
      final meses = (dias / 30).ceil();
      return meses == 1
          ? 'No ritmo atual, cerca de 1 mês.'
          : 'No ritmo atual, cerca de $meses meses.';
    }
    final anos = (dias / 365).ceil();
    return anos == 1
        ? 'No ritmo atual, cerca de 1 ano.'
        : 'No ritmo atual, cerca de $anos anos.';
  }
}
