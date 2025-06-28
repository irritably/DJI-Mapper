import 'dart:convert';

import 'package:dji_mapper/main.dart';

class OrbitSettings {
  double radius;
  int points;
  bool clockwise;
  bool facePoi;

  OrbitSettings({
    required this.radius,
    required this.points,
    required this.clockwise,
    required this.facePoi,
  });

  Map<String, dynamic> toJson() {
    return {
      'radius': radius,
      'points': points,
      'clockwise': clockwise,
      'facePoi': facePoi,
    };
  }

  factory OrbitSettings.fromJson(Map<String, dynamic> json) {
    return OrbitSettings(
      radius: json['radius'] ?? 100.0,
      points: json['points'] ?? 8,
      clockwise: json['clockwise'] ?? true,
      facePoi: json['facePoi'] ?? true,
    );
  }

  static final _defaultSettings = OrbitSettings(
    radius: 100.0,
    points: 8,
    clockwise: true,
    facePoi: true,
  );

  static OrbitSettings getOrbitSettings() {
    return OrbitSettings.fromJson(jsonDecode(
        prefs.getString("orbitSettings") ??
            jsonEncode(_defaultSettings.toJson())));
  }

  static void saveOrbitSettings(OrbitSettings settings) {
    prefs.setString("orbitSettings", jsonEncode(settings.toJson()));
  }
}