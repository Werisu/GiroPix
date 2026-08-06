import '../local/hive_service.dart';
import '../models/corrida.dart';

class CorridaRepository {
  Future<List<Corrida>> getAll() async {
    final list = HiveService.corridas.values.toList();
    list.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return list;
  }

  Future<void> save(Corrida corrida) async {
    await HiveService.corridas.put(corrida.id, corrida);
  }

  Future<void> delete(String id) async {
    await HiveService.corridas.delete(id);
  }

  Future<Corrida?> getById(String id) async {
    return HiveService.corridas.get(id);
  }
}
