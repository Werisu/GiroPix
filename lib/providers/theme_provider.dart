import 'package:flutter/foundation.dart';

import '../core/theme/app_theme.dart';
import '../data/local/hive_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider() : _palette = AppPalette.byId(HiveService.getAppPaletteId());

  AppPalette _palette;

  AppPalette get palette => _palette;

  Future<void> setPalette(AppPalette palette) async {
    if (palette.id == _palette.id) return;
    _palette = palette;
    await HiveService.setAppPaletteId(palette.id);
    notifyListeners();
  }
}
