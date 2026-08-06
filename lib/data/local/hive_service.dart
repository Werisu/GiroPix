import 'package:hive_flutter/hive_flutter.dart';

import '../models/corrida.dart';
import '../models/gasto.dart';

class HiveService {
  static const String corridasBox = 'corridas';
  static const String gastosBox = 'gastos';
  static const String settingsBox = 'settings';

  static const String keyTaxaPadraoPercent = 'taxa_padrao_percent';
  static const double taxaPadraoDefault = 15.0;

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CorridaAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(GastoAdapter());
    }

    await Future.wait([
      Hive.openBox<Corrida>(corridasBox),
      Hive.openBox<Gasto>(gastosBox),
      Hive.openBox(settingsBox),
    ]);
  }

  static Box<Corrida> get corridas => Hive.box<Corrida>(corridasBox);
  static Box<Gasto> get gastos => Hive.box<Gasto>(gastosBox);
  static Box get settings => Hive.box(settingsBox);

  static double getTaxaPadraoPercent() {
    return (settings.get(keyTaxaPadraoPercent) as num?)?.toDouble() ??
        taxaPadraoDefault;
  }

  static Future<void> setTaxaPadraoPercent(double percent) async {
    await settings.put(keyTaxaPadraoPercent, percent);
  }
}
