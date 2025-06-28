import 'dart:convert';

import 'package:dji_mapper/main.dart';

class FacadeSettings {
  int facadeHeight;
  double facadeDistanceFromBuilding;
  int facadeFrontOverlap;
  int facadeSideOverlap;
  int facadeCameraPitch;

  FacadeSettings({
    required this.facadeHeight,
    required this.facadeDistanceFromBuilding,
    required this.facadeFrontOverlap,
    required this.facadeSideOverlap,
    required this.facadeCameraPitch,
  });

  Map<String, dynamic> toJson() {
    return {
      'facadeHeight': facadeHeight,
      'facadeDistanceFromBuilding': facadeDistanceFromBuilding,
      'facadeFrontOverlap': facadeFrontOverlap,
      'facadeSideOverlap': facadeSideOverlap,
      'facadeCameraPitch': facadeCameraPitch,
    };
  }

  factory FacadeSettings.fromJson(Map<String, dynamic> json) {
    return FacadeSettings(
      facadeHeight: json['facadeHeight'] ?? 30,
      facadeDistanceFromBuilding: json['facadeDistanceFromBuilding'] ?? 20.0,
      facadeFrontOverlap: json['facadeFrontOverlap'] ?? 80,
      facadeSideOverlap: json['facadeSideOverlap'] ?? 60,
      facadeCameraPitch: json['facadeCameraPitch'] ?? -45,
    );
  }

  static final _defaultSettings = FacadeSettings(
    facadeHeight: 30,
    facadeDistanceFromBuilding: 20.0,
    facadeFrontOverlap: 80,
    facadeSideOverlap: 60,
    facadeCameraPitch: -45,
  );

  static FacadeSettings getFacadeSettings() {
    return FacadeSettings.fromJson(jsonDecode(
        prefs.getString("facadeSettings") ??
            jsonEncode(_defaultSettings.toJson())));
  }

  static void saveFacadeSettings(FacadeSettings settings) {
    prefs.setString("facadeSettings", jsonEncode(settings.toJson()));
  }
}