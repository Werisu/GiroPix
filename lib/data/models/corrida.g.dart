// Gerado manualmente (TypeAdapter Hive) para Corrida.
// ignore_for_file: dangling_library_doc_comments

part of 'corrida.dart';

class CorridaAdapter extends TypeAdapter<Corrida> {
  @override
  final int typeId = 0;

  @override
  Corrida read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Corrida(
      id: fields[0] as String,
      dataHora: fields[1] as DateTime,
      valorBruto: fields[2] as double,
      formaPagamento: fields[3] as String,
      taxaApp: fields[4] as double,
      plataforma: fields[5] as String? ?? 'Outro',
    );
  }

  @override
  void write(BinaryWriter writer, Corrida obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dataHora)
      ..writeByte(2)
      ..write(obj.valorBruto)
      ..writeByte(3)
      ..write(obj.formaPagamento)
      ..writeByte(4)
      ..write(obj.taxaApp)
      ..writeByte(5)
      ..write(obj.plataforma);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorridaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
