import '../local/hive_service.dart';
import '../models/gasto.dart';

class GastoRepository {
  Future<List<Gasto>> getAll() async {
    final list = HiveService.gastos.values.toList();
    list.sort((a, b) => b.data.compareTo(a.data));
    return list;
  }

  Future<void> save(Gasto gasto) async {
    await HiveService.gastos.put(gasto.id, gasto);
  }

  Future<void> delete(String id) async {
    await HiveService.gastos.delete(id);
  }

  Future<Gasto?> getById(String id) async {
    return HiveService.gastos.get(id);
  }
}
