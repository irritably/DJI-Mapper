import 'package:dji_mapper/components/text_field.dart';
import 'package:dji_mapper/shared/facade_settings.dart';
import 'package:dji_mapper/shared/value_listeneables.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FacadeBar extends StatefulWidget {
  const FacadeBar({super.key});

  @override
  State<FacadeBar> createState() => _FacadeBarState();
}

class _FacadeBarState extends State<FacadeBar> {
  @override
  void initState() {
    super.initState();
    _loadFacadeSettings();
  }

  void _loadFacadeSettings() {
    final settings = FacadeSettings.getFacadeSettings();
    final listenables = Provider.of<ValueListenables>(context, listen: false);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      listenables.facadeHeight = settings.facadeHeight;
      listenables.facadeDistanceFromBuilding = settings.facadeDistanceFromBuilding;
      listenables.facadeFrontOverlap = settings.facadeFrontOverlap;
      listenables.facadeSideOverlap = settings.facadeSideOverlap;
      listenables.facadeCameraPitch = settings.facadeCameraPitch;
    });
  }

  void _updateSettings(ValueListenables listenables) {
    FacadeSettings.saveFacadeSettings(FacadeSettings(
      facadeHeight: listenables.facadeHeight,
      facadeDistanceFromBuilding: listenables.facadeDistanceFromBuilding,
      facadeFrontOverlap: listenables.facadeFrontOverlap,
      facadeSideOverlap: listenables.facadeSideOverlap,
      facadeCameraPitch: listenables.facadeCameraPitch,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ValueListenables>(builder: (context, listenables, child) {
      return SingleChildScrollView(
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text("Facade Mission Mode"),
                      subtitle: const Text("Enable facade mapping planning"),
                      value: listenables.facadeMode,
                      onChanged: (value) {
                        listenables.facadeMode = value;
                        if (!value) {
                          // Clear facade line when disabling facade mode
                          listenables.facadeLine.clear();
                        }
                      },
                    ),
                    if (listenables.facadeMode) ...[
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Draw the facade line on the map by clicking points along the building face",
                          style: TextStyle(fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (listenables.facadeLine.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Facade line: ${listenables.facadeLine.length} points",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            if (listenables.facadeMode && listenables.facadeLine.length >= 2) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const Text(
                        "Facade Parameters",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        labelText: "Facade Height (m)",
                        min: 5,
                        max: 200,
                        defaultValue: listenables.facadeHeight.toDouble(),
                        onChanged: (value) {
                          listenables.facadeHeight = value.round();
                          _updateSettings(listenables);
                        },
                      ),
                      CustomTextField(
                        labelText: "Distance from Building (m)",
                        min: 5,
                        max: 100,
                        defaultValue: listenables.facadeDistanceFromBuilding,
                        onChanged: (value) {
                          listenables.facadeDistanceFromBuilding = value;
                          _updateSettings(listenables);
                        },
                        decimals: 1,
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const Text(
                        "Image Overlap",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        labelText: "Front Overlap (%)",
                        min: 60,
                        max: 90,
                        defaultValue: listenables.facadeFrontOverlap.toDouble(),
                        onChanged: (value) {
                          listenables.facadeFrontOverlap = value.round();
                          _updateSettings(listenables);
                        },
                      ),
                      CustomTextField(
                        labelText: "Side Overlap (%)",
                        min: 40,
                        max: 80,
                        defaultValue: listenables.facadeSideOverlap.toDouble(),
                        onChanged: (value) {
                          listenables.facadeSideOverlap = value.round();
                          _updateSettings(listenables);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const Text(
                        "Camera Settings",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        labelText: "Camera Pitch (deg)",
                        min: -90,
                        max: 0,
                        defaultValue: listenables.facadeCameraPitch.toDouble(),
                        onChanged: (value) {
                          listenables.facadeCameraPitch = value.round();
                          _updateSettings(listenables);
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Camera will face the facade perpendicular to the flight line",
                        style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}