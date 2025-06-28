import 'package:dji_mapper/components/text_field.dart';
import 'package:dji_mapper/shared/orbit_settings.dart';
import 'package:dji_mapper/shared/value_listeneables.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrbitBar extends StatefulWidget {
  const OrbitBar({super.key});

  @override
  State<OrbitBar> createState() => _OrbitBarState();
}

class _OrbitBarState extends State<OrbitBar> {
  @override
  void initState() {
    super.initState();
    _loadOrbitSettings();
  }

  void _loadOrbitSettings() {
    final settings = OrbitSettings.getOrbitSettings();
    final listenables = Provider.of<ValueListenables>(context, listen: false);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      listenables.orbitRadius = settings.radius;
      listenables.orbitPoints = settings.points;
      listenables.orbitClockwise = settings.clockwise;
      listenables.orbitFacePoi = settings.facePoi;
    });
  }

  void _updateSettings(ValueListenables listenables) {
    OrbitSettings.saveOrbitSettings(OrbitSettings(
      radius: listenables.orbitRadius,
      points: listenables.orbitPoints,
      clockwise: listenables.orbitClockwise,
      facePoi: listenables.orbitFacePoi,
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
                      title: const Text("Orbit Mission Mode"),
                      subtitle: const Text("Enable orbit mission planning"),
                      value: listenables.orbitMode,
                      onChanged: (value) {
                        listenables.orbitMode = value;
                        if (!value) {
                          // Clear POI when disabling orbit mode
                          listenables.orbitPoi = null;
                          listenables.selectingPoi = false;
                        }
                      },
                    ),
                    if (listenables.orbitMode) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  listenables.selectingPoi = !listenables.selectingPoi;
                                },
                                icon: Icon(listenables.selectingPoi 
                                    ? Icons.cancel 
                                    : Icons.my_location),
                                label: Text(listenables.selectingPoi 
                                    ? "Cancel Selection" 
                                    : "Select POI on Map"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: listenables.selectingPoi 
                                      ? Theme.of(context).colorScheme.error
                                      : null,
                                  foregroundColor: listenables.selectingPoi 
                                      ? Theme.of(context).colorScheme.onError
                                      : null,
                                ),
                              ),
                            ),
                            if (listenables.orbitPoi != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {
                                  listenables.orbitPoi = null;
                                },
                                icon: const Icon(Icons.clear),
                                tooltip: "Clear POI",
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (listenables.orbitPoi != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "POI: ${listenables.orbitPoi!.latitude.toStringAsFixed(6)}, ${listenables.orbitPoi!.longitude.toStringAsFixed(6)}",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            if (listenables.orbitMode && listenables.orbitPoi != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      CustomTextField(
                        labelText: "Orbit Radius (m)",
                        min: 10,
                        max: 1000,
                        defaultValue: listenables.orbitRadius,
                        onChanged: (value) {
                          listenables.orbitRadius = value;
                          _updateSettings(listenables);
                        },
                        decimals: 1,
                      ),
                      CustomTextField(
                        labelText: "Number of Waypoints",
                        min: 4,
                        max: 50,
                        defaultValue: listenables.orbitPoints.toDouble(),
                        onChanged: (value) {
                          listenables.orbitPoints = value.round();
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
                        "Orbit Direction:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        children: [
                          ChoiceChip(
                            label: const Text('Clockwise'),
                            selected: listenables.orbitClockwise,
                            onSelected: (selected) {
                              if (selected) {
                                listenables.orbitClockwise = true;
                                _updateSettings(listenables);
                              }
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Counter-Clockwise'),
                            selected: !listenables.orbitClockwise,
                            onSelected: (selected) {
                              if (selected) {
                                listenables.orbitClockwise = false;
                                _updateSettings(listenables);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text("Face POI"),
                        subtitle: const Text("Gimbal faces the point of interest"),
                        value: listenables.orbitFacePoi,
                        onChanged: (value) {
                          listenables.orbitFacePoi = value;
                          _updateSettings(listenables);
                        },
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