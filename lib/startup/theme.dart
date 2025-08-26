import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';

({ThemeData light, ThemeData dark}) loadThemes() {
  ThemeData light = ThemeStruct.getLightTheme().data;
  ThemeData dark = ThemeStruct.getDarkTheme().data;

  final Tuple2<ThemeData, ThemeData> tuple = ts.getStructsFromData(light, dark);
  light = tuple.item1;
  dark = tuple.item2;

  return (light: light, dark: dark);
}
