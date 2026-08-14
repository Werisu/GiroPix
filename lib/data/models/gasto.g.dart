// Gerado manualmente (TypeAdapter Hive) para Gasto.
// ignore_for_file: dangling_library_doc_comments

part of 'gasto.dart';

class GastoAdapter extends TypeAdapter<Gasto> {
  @override
  final int typeId = 1;

  @override
  Gasto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Gasto(
      id: fields[0] as String,
      data: fields[1] as DateTime,
      combustivel: fields[2] as double,
      alimentacao: fields[3] as double,
      outros: fields[4] as double,
      updatedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Gasto obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.data)
      ..writeByte(2)
      ..write(obj.combustivel)
      ..writeByte(3)
      ..write(obj.alimentacao)
      ..writeByte(4)
      ..write(obj.outros)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GastoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
