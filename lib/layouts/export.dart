import 'package:dji_mapper/core/drone_mapper_format.dart';
import 'package:dji_mapper/shared/map_provider.dart';
import 'package:flutter_map/flutter_map.dart' hide Polygon;
import 'package:geoxml/geoxml.dart';
import 'package:latlong2/latlong.dart';
import 'package:universal_io/io.dart';
import 'package:dji_mapper/components/popups/dji_load_alert.dart';
import 'package:dji_mapper/components/popups/litchi_load_alert.dart';
import 'package:dji_mapper/main.dart';
import 'package:litchi_waypoint_engine/engine.dart' as litchi;
import 'package:universal_html/html.dart' as html;
import 'package:archive/archive.dart';
import 'package:dji_waypoint_engine/engine.dart';
import 'package:dji_mapper/shared/value_listeneables.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:provider/provider.dart';
import 'dart:math' as math;

class ExportBar extends StatefulWidget {
  const ExportBar({super.key});

  @override
  State<ExportBar> createState() => ExportBarState();
}

class ExportBarState extends State<ExportBar> {
  Future<void> _exportForDJIFly(ValueListenables listenables) async {
    var missionConfig = MissionConfig(

        /// Always fly safely
        /// This is the default for DJI Fly anyway
        flyToWaylineMode: FlyToWaylineMode.safely,

        /// This will be added later
        finishAction: listenables.onFinished,

        /// To comply with EU regulations
        /// Always execute lost action on RC signal lost
        /// do not continue the mission
        exitOnRCLost: ExitOnRCLost.executeLostAction,

        /// For now it's deafult to go back home on RC signal lost
        rcLostAction: listenables.rcLostAction,

        /// The speed to the first waypoint
        /// For now this is the general speed of the mission
        globalTransitionalSpeed: listenables.speed,

        /// Drone information for DJI Fly is default at 68
        /// Unsure what other values there can be
        /// Can't find official documentation
        droneInfo: DroneInfo(droneEnumValue: 68));

    var template = TemplateKml(
        document: KmlDocumentElement(

            /// The author is always `fly` for now
            author: "fly",
            creationTime: DateTime.now(),
            modificationTime: DateTime.now(),

            /// The template and waylines take the same mission config
            /// Not sure why duplication is necessary
            missionConfig: missionConfig));

    var placemarks = _generateDjiPlacemarks(listenables);

    if (placemarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("No waypoints to export. Please add waypoints first")));
      return;
    }

    var waylines = WaylinesWpml(
        document: WpmlDocumentElement(
            missionConfig: missionConfig,
            folderElement: FolderElement(
                templateId: 0, // Only one mission, so this is always 0
                waylineId: 0, // Only one wayline, so this is always 0
                speed: listenables.speed,
                placemarks: placemarks)));

    var templateString = template.toXmlString(pretty: true);
    var waylinesString = waylines.toXmlString(pretty: true);

    var encoder = ZipEncoder();
    var archive = Archive();

    archive.addFile(ArchiveFile('template.kml', templateString.length,
        Uint8List.fromList(templateString.codeUnits)));

    archive.addFile(ArchiveFile('waylines.wpml', waylinesString.length,
        Uint8List.fromList(waylinesString.codeUnits)));

    var zipData = encoder.encode(archive);
    var zipBytes = Uint8List.fromList(zipData!);

    String? outputPath;

    if (!kIsWeb) {
      outputPath = await FilePicker.platform.saveFile(
          type: FileType.custom,
          fileName: "output",
          allowedExtensions: ["kmz"],
          dialogTitle: "Save Mission");

      if (outputPath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Mission export cancelled")));
        }
        return;
      }

      // File Saver does not save the file on Desktop platforms
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        if (!outputPath.endsWith(".kmz")) {
          outputPath += ".kmz";
        }
        // Save file for non-web platforms
        final file = File(outputPath);
        await file.writeAsBytes(zipBytes);
      }
    } else {
      // Save file for web platform
      outputPath = "output.kmz";
      final blob = html.Blob([zipBytes], 'application/octet-stream');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "output.kmz")
        ..click();
      html.Url.revokeObjectUrl(url);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mission exported successfully")));

      if (!(prefs.getBool("djiWarningDoNotShow") ?? false)) {
        showDialog(
            context: context, builder: (context) => const DjiLoadAlert());
      }
    }
  }

  Future<void> _exportForLithi(ValueListenables listenables) async {
    final waypoints = _generateLitchiWaypoints(listenables);

    if (waypoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("No waypoints to export. Please add waypoints first")));
      return;
    }

    String csvContent = litchi.LitchiCsv.generateCsv(waypoints);

    String? outputPath;

    if (!kIsWeb) {
      outputPath = await FilePicker.platform.saveFile(
          type: FileType.custom,
          fileName: "litchi_mission",
          allowedExtensions: ["csv"],
          dialogTitle: "Save Mission");

      if (outputPath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Mission export cancelled")));
        }
        return;
      }

      // File Saver does not save the file on Desktop platforms
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        if (!outputPath.endsWith(".csv")) {
          outputPath += ".csv";
        }
        // Save file for non-web platforms
        final file = File(outputPath);
        await file.writeAsString(csvContent);
      }
    } else {
      // Save file for web platform
      outputPath = "output.csv";
      final blob = html.Blob([csvContent], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "litchi_mission.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mission exported successfully")));
      if (!(prefs.getBool("litchiWarningDoNotShow") ?? false)) {
        showDialog(
            context: context, builder: (context) => const LitchiLoadAlert());
      }
    }
  }

  List<litchi.Waypoint> _generateLitchiWaypoints(ValueListenables listenables) {
    var waypoints = <litchi.Waypoint>[];

    for (var photoLocation in listenables.photoLocations) {
      var actions = <litchi.Action>[];
      
      // Add delay action if specified
      if (listenables.delayAtWaypoint > 0) {
        actions.add(litchi.Action(
          actionType: litchi.ActionType.stayFor,
          actionParam: listenables.delayAtWaypoint.toDouble() * 1000, // Litchi uses milliseconds
        ));
      }
      
      // Add photo action if camera points are enabled
      if (listenables.createCameraPoints) {
        actions.add(litchi.Action(actionType: litchi.ActionType.takePhoto));
      }

      // Calculate heading for facade missions
      double? heading;
      if (listenables.facadeMode && listenables.facadeLine.length >= 2) {
        heading = _calculateFacadeHeading(listenables.facadeLine, photoLocation);
      }

      waypoints.add(litchi.Waypoint(
        latitude: photoLocation.latitude,
        longitude: photoLocation.longitude,
        altitude: listenables.altitude,
        speed: listenables.speed.toInt(),
        heading: heading,
        gimbalPitch: listenables.facadeMode ? listenables.facadeCameraPitch : listenables.cameraAngle,
        gimbalMode: _getLitchiGimbalMode(listenables),
        poi: _getLitchiPoi(listenables),
        actions: actions,
      ));
    }

    return waypoints;
  }

  double _calculateFacadeHeading(List<LatLng> facadeLine, LatLng waypoint) {
    // Find the closest segment on the facade line and calculate perpendicular heading
    double minDistance = double.infinity;
    double heading = 0;

    for (int i = 0; i < facadeLine.length - 1; i++) {
      LatLng p1 = facadeLine[i];
      LatLng p2 = facadeLine[i + 1];
      
      // Calculate bearing of the facade segment
      double facadeBearing = _calculateBearing(p1, p2);
      
      // Perpendicular heading (90 degrees to the facade)
      double perpHeading = (facadeBearing + 90) % 360;
      
      // Calculate distance from waypoint to this segment
      double distance = _distanceToLineSegment(waypoint, p1, p2);
      
      if (distance < minDistance) {
        minDistance = distance;
        heading = perpHeading;
      }
    }

    return heading;
  }

  double _calculateBearing(LatLng from, LatLng to) {
    double lat1 = from.latitude * math.pi / 180;
    double lat2 = to.latitude * math.pi / 180;
    double deltaLng = (to.longitude - from.longitude) * math.pi / 180;

    double y = math.sin(deltaLng) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);

    double bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  double _distanceToLineSegment(LatLng point, LatLng lineStart, LatLng lineEnd) {
    // Simplified distance calculation - in a real implementation you'd want more precision
    double A = point.latitude - lineStart.latitude;
    double B = point.longitude - lineStart.longitude;
    double C = lineEnd.latitude - lineStart.latitude;
    double D = lineEnd.longitude - lineStart.longitude;

    double dot = A * C + B * D;
    double lenSq = C * C + D * D;
    
    if (lenSq == 0) return math.sqrt(A * A + B * B);
    
    double param = dot / lenSq;
    
    double xx, yy;
    if (param < 0) {
      xx = lineStart.latitude;
      yy = lineStart.longitude;
    } else if (param > 1) {
      xx = lineEnd.latitude;
      yy = lineEnd.longitude;
    } else {
      xx = lineStart.latitude + param * C;
      yy = lineStart.longitude + param * D;
    }

    double dx = point.latitude - xx;
    double dy = point.longitude - yy;
    return math.sqrt(dx * dx + dy * dy);
  }

  litchi.GimbalMode _getLitchiGimbalMode(ValueListenables listenables) {
    if (listenables.orbitMode && listenables.orbitFacePoi) {
      return litchi.GimbalMode.focusPoi;
    }
    return litchi.GimbalMode.interpolate;
  }

  litchi.Poi? _getLitchiPoi(ValueListenables listenables) {
    if (listenables.orbitMode && listenables.orbitFacePoi && listenables.orbitPoi != null) {
      return litchi.Poi(
        latitude: listenables.orbitPoi!.latitude,
        longitude: listenables.orbitPoi!.longitude,
        altitude: listenables.altitude,
      );
    }
    return null;
  }

  List<Placemark> _generateDjiPlacemarks(ValueListenables listenables) {
    var placemarks = <Placemark>[];

    for (var photoLocation in listenables.photoLocations) {
      int id = listenables.photoLocations.indexOf(photoLocation);
      
      var actions = <Action>[];
      
      // Set gimbal angle on first waypoint
      if (id == 0) {
        int gimbalPitch = listenables.facadeMode ? listenables.facadeCameraPitch : listenables.cameraAngle;
        actions.add(Action(
          id: id,
          actionFunction: ActionFunction.gimbalEvenlyRotate,
          actionParams: GimbalRotateParams(
            pitch: gimbalPitch.toDouble(),
            payloadPosition: 0,
          ),
        ));
      }
      
      // Add delay action if specified
      if (listenables.delayAtWaypoint > 0) {
        actions.add(Action(
          id: id,
          actionFunction: ActionFunction.hover,
          actionParams: HoverParams(hoverTime: listenables.delayAtWaypoint),
        ));
      }
      
      // Add photo action if camera points are enabled
      if (listenables.createCameraPoints) {
        actions.add(Action(
          id: id,
          actionFunction: ActionFunction.takePhoto,
          actionParams: CameraControlParams(payloadPosition: 0),
        ));
      }

      placemarks.add(Placemark(
        point: WaypointPoint(
          longitude: photoLocation.longitude,
          latitude: photoLocation.latitude,
        ),
        index: id,
        height: listenables.altitude,
        speed: listenables.speed,
        headingParam: _getDjiHeadingParam(listenables, photoLocation),
        turnParam: TurnParam(
          waypointTurnMode: WaypointTurnMode.toPointAndStopWithDiscontinuityCurvature,
          turnDampingDistance: 0,
        ),
        useStraightLine: true,
        actionGroup: actions.isNotEmpty ? ActionGroup(
          id: 0,
          startIndex: id,
          endIndex: id,
          actions: actions,
          mode: ActionMode.sequence,
          trigger: ActionTriggerType.reachPoint,
        ) : null,
      ));
    }

    return placemarks;
  }

  HeadingParam _getDjiHeadingParam(ValueListenables listenables, LatLng waypoint) {
    if (listenables.orbitMode && listenables.orbitFacePoi && listenables.orbitPoi != null) {
      return HeadingParam(
        headingMode: HeadingMode.towardPOI,
        headingPathMode: HeadingPathMode.followBadArc,
        headingAngleEnable: false,
        poiPoint: PoiPoint(
          longitude: listenables.orbitPoi!.longitude,
          latitude: listenables.orbitPoi!.latitude,
          height: listenables.altitude.toDouble(),
        ),
      );
    }
    
    if (listenables.facadeMode && listenables.facadeLine.length >= 2) {
      // Calculate heading to face the facade
      double heading = _calculateFacadeHeading(listenables.facadeLine, waypoint);
      return HeadingParam(
        headingMode: HeadingMode.fixed,
        headingPathMode: HeadingPathMode.followBadArc,
        headingAngleEnable: true,
        headingAngle: heading.round(),
      );
    }
    
    return HeadingParam(
      headingMode: HeadingMode.followWayline,
      headingPathMode: HeadingPathMode.followBadArc,
      headingAngleEnable: false,
    );
  }

  Future<void> _importFromKml(ValueListenables listenables) async {
    var file = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ["kml"],
        dialogTitle: "Load Area");

    if (file == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("No file selected. Import cancelled")));
      }
      return;
    }

    late DroneMapperXml kml;

    if (kIsWeb) {
      kml = await DroneMapperXml.fromKmlString(
          String.fromCharCodes(file.files.first.bytes!));
    } else {
      kml = await DroneMapperXml.fromKmlString(
          await File(file.files.single.path!).readAsString());
    }

    if (kml.polygons.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("No polygons found in KML. Import cancelled")));
      return;
    } else if (kml.polygons.length > 1) {
      if (mounted) {
        int selectedPolygon = 0;
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Select Polygon"),
              content: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                          "Multiple polygons found in the KML file, please select one"),
                      const Divider(),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        width: 400,
                        child: ListView.separated(
                          itemCount: kml.polygons.length,
                          itemBuilder: (context, index) => CheckboxListTile(
                            value: selectedPolygon == index,
                            onChanged: (value) {
                              setState(() {
                                selectedPolygon = index;
                              });
                            },
                            title: Text(
                                kml.polygons[index].name ?? "Polygon $index"),
                          ),
                          separatorBuilder: (context, index) => const Divider(),
                          shrinkWrap: true,
                        ),
                      ),
                    ],
                  );
                },
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel")),
                FilledButton(
                    onPressed: () {
                      // Ensure a polygon is selected before proceeding
                      if (selectedPolygon >= 0 &&
                          selectedPolygon < kml.polygons.length) {
                        _loadPolygon(
                          kml.polygons[selectedPolygon].outerBoundaryIs.rtepts
                              .map((e) => LatLng(e.lat!, e.lon!))
                              .toList(),
                        );
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text("Load")),
              ],
            );
          },
        );
      }
      return;
    } else {
      _loadPolygon(kml.polygons.first.outerBoundaryIs.rtepts
          .map((e) => LatLng(e.lat!, e.lon!))
          .toList());
      return;
    }
  }

  Future<void> _loadPolygon(List<LatLng> polygon) async {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final mapController = mapProvider.mapController;

    Provider.of<ValueListenables>(context, listen: false).polygon = polygon;

    if (polygon.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(polygon);

      mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(80),
          maxZoom: 18.0,
        ),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Area imported successfully")),
      );
    }
  }

  Future<void> _exportAreaToKml(ValueListenables listenables) async {
    if (listenables.polygon.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("No polygon to export. Please add waypoints first")));
      return;
    }
    var kml = DroneMapperXml();
    kml.polygons = [
      Polygon(
        name: "Mapping Area",
        outerBoundaryIs: Rte(
            rtepts: listenables.polygon
                .map((element) =>
                    Wpt(lat: element.latitude, lon: element.longitude))
                .toList()),
      )
    ];

    var kmlString = kml.toKmlString(pretty: true);

    String? outputPath;

    if (!kIsWeb) {
      outputPath = await FilePicker.platform.saveFile(
          type: FileType.custom,
          fileName: "area",
          allowedExtensions: ["kml"],
          dialogTitle: "Save Area");

      if (outputPath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Area export cancelled")));
        }
        return;
      }

      // File Saver does not save the file on Desktop platforms
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        if (!outputPath.endsWith(".kml")) {
          outputPath += ".kml";
        }
        // Save file for non-web platforms
        final file = File(outputPath);
        await file.writeAsBytes(Uint8List.fromList(kmlString.codeUnits));
      }
    } else {
      // Save file for web platform
      outputPath = "area.kml";
      final blob = html.Blob([Uint8List.fromList(kmlString.codeUnits)],
          'application/octet-stream');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "area.kml")
        ..click();
      html.Url.revokeObjectUrl(url);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Area exported successfully")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Consumer<ValueListenables>(builder: (context, listenables, child) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Export your Survey Mission",
                  style: TextStyle(fontSize: 20)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: () => _exportForDJIFly(listenables),
                  child: const Text("Save as DJI Fly Waypoint Mission")),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: () => _exportForLithi(listenables),
                  child: const Text("Save as Litchi Mission")),
            ),
            if (!listenables.orbitMode && !listenables.facadeMode) ...[
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Import/Export Mapping Area",
                    style: TextStyle(fontSize: 20)),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Tooltip(
                      message: "This will override the current mapping area",
                      child: ElevatedButton(
                          onPressed: () => _importFromKml(listenables),
                          child: const Text("Import from KML")),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ElevatedButton(
                        onPressed: () => _exportAreaToKml(listenables),
                        child: const Text("Export to KML")),
                  ),
                ],
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    border: Border.all(
                        width: 3,
                        color:
                            Theme.of(context).colorScheme.error.withAlpha(127)),
                    color: Theme.of(context)
                        .colorScheme
                        .errorContainer
                        .withAlpha(25),
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        "Warning",
                        style: TextStyle(
                            fontSize: 20,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "I am not responsible for any damage or loss of equipment or data. Use at your own risk.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "If you notice any issues during the mission, please stop the mission immediately.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            )
          ],
        );
      }),
    );
  }
}