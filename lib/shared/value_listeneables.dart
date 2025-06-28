import 'package:dji_mapper/presets/camera_preset.dart';
import 'package:dji_waypoint_engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ValueListenables extends ChangeNotifier {
  /// Altitude in meters
  final _altitude = ValueNotifier<int>(50);
  int get altitude => _altitude.value;
  set altitude(int value) {
    _altitude.value = value;
    notifyListeners();
  }

  /// Forward overlap in percentage
  final _forwardOverlap = ValueNotifier<int>(60);
  int get forwardOverlap => _forwardOverlap.value;
  set forwardOverlap(int value) {
    _forwardOverlap.value = value;
    notifyListeners();
  }

  /// Side overlap in percentage
  final _sideOverlap = ValueNotifier<int>(40);
  int get sideOverlap => _sideOverlap.value;
  set sideOverlap(int value) {
    _sideOverlap.value = value;
    notifyListeners();
  }

  final _rotation = ValueNotifier<int>(0);
  int get rotation => _rotation.value;
  set rotation(int value) {
    _rotation.value = value;
    notifyListeners();
  }

  /// Speed in m/s
  final _speed = ValueNotifier<double>(4.0);
  double get speed => _speed.value;
  set speed(double value) {
    _speed.value = value;
    notifyListeners();
  }

  final _cameraAngle = ValueNotifier<int>(-90);
  int get cameraAngle => _cameraAngle.value;
  set cameraAngle(int value) {
    _cameraAngle.value = value;
    notifyListeners();
  }

  /// Sensor width in mm
  final _sensorWidth = ValueNotifier<double>(13.2);
  double get sensorWidth => _sensorWidth.value;
  set sensorWidth(double value) {
    _sensorWidth.value = value;
    notifyListeners();
  }

  /// Sensor height in mm
  final _sensorHeight = ValueNotifier<double>(8.8);
  double get sensorHeight => _sensorHeight.value;
  set sensorHeight(double value) {
    _sensorHeight.value = value;
    notifyListeners();
  }

  /// Focal length in mm
  final _focalLength = ValueNotifier<double>(8.8);
  double get focalLength => _focalLength.value;
  set focalLength(double value) {
    _focalLength.value = value;
    notifyListeners();
  }

  /// Image width in pixels
  final _imageWidth = ValueNotifier<int>(4000);
  int get imageWidth => _imageWidth.value;
  set imageWidth(int value) {
    _imageWidth.value = value;
    notifyListeners();
  }

  /// Image height in pixels
  final _imageHeight = ValueNotifier<int>(3000);
  int get imageHeight => _imageHeight.value;
  set imageHeight(int value) {
    _imageHeight.value = value;
    notifyListeners();
  }

  /// Delay at waypoint in seconds
  final _delayAtWaypoint = ValueNotifier<int>(0);
  int get delayAtWaypoint => _delayAtWaypoint.value;
  set delayAtWaypoint(int value) {
    _delayAtWaypoint.value = value;
    notifyListeners();
  }

  /// Show point locations
  final _showPoints = ValueNotifier<bool>(false);
  bool get showPoints => _showPoints.value;
  set showPoints(bool value) {
    _showPoints.value = value;
    notifyListeners();
  }

  /// fill the generated flight grid with a crosshatch flight pattern
  final _fillGrid = ValueNotifier<bool>(false);
  bool get fillGrid => _fillGrid.value;
  set fillGrid(bool value) {
    _fillGrid.value = value;
    notifyListeners();
  }

  /// Create camera point locations
  final _createCameraPoints = ValueNotifier<bool>(false);
  bool get createCameraPoints => _createCameraPoints.value;
  set createCameraPoints(bool value) {
    _createCameraPoints.value = value;
    notifyListeners();
  }

  /// What to do when the mission is finished
  final _onFinished = ValueNotifier<FinishAction>(FinishAction.noAction);
  FinishAction get onFinished => _onFinished.value;
  set onFinished(FinishAction value) {
    _onFinished.value = value;
    notifyListeners();
  }

  /// What to do when the drone loses connection
  final _rcLostAction = ValueNotifier<RCLostAction>(RCLostAction.hover);
  RCLostAction get rcLostAction => _rcLostAction.value;
  set rcLostAction(RCLostAction value) {
    _rcLostAction.value = value;
    notifyListeners();
  }

  /// Polygon of the area to map
  final _polygon = ValueNotifier<List<LatLng>>([]);
  List<LatLng> get polygon => _polygon.value;
  set polygon(List<LatLng> value) {
    _polygon.value = value;
    notifyListeners();
  }

  /// List of photo markers
  final _photoLocations = ValueNotifier<List<LatLng>>([]);
  List<LatLng> get photoLocations => _photoLocations.value;
  set photoLocations(List<LatLng> value) {
    _photoLocations.value = value;
    notifyListeners();
  }

  /// Flight line
  final _flightLine = ValueNotifier<Polyline?>(null);
  Polyline? get flightLine => _flightLine.value;
  set flightLine(Polyline? value) {
    _flightLine.value = value;
    notifyListeners();
  }

  final _selectedCameraPreset = ValueNotifier<CameraPreset?>(null);
  CameraPreset? get selectedCameraPreset => _selectedCameraPreset.value;
  set selectedCameraPreset(CameraPreset? value) {
    _selectedCameraPreset.value = value;
  }

  /// Orbit mission mode
  final _orbitMode = ValueNotifier<bool>(false);
  bool get orbitMode => _orbitMode.value;
  set orbitMode(bool value) {
    _orbitMode.value = value;
    notifyListeners();
  }

  /// Orbit POI (Point of Interest)
  final _orbitPoi = ValueNotifier<LatLng?>(null);
  LatLng? get orbitPoi => _orbitPoi.value;
  set orbitPoi(LatLng? value) {
    _orbitPoi.value = value;
    notifyListeners();
  }

  /// Orbit radius in meters
  final _orbitRadius = ValueNotifier<double>(100.0);
  double get orbitRadius => _orbitRadius.value;
  set orbitRadius(double value) {
    _orbitRadius.value = value;
    notifyListeners();
  }

  /// Number of orbit waypoints
  final _orbitPoints = ValueNotifier<int>(8);
  int get orbitPoints => _orbitPoints.value;
  set orbitPoints(int value) {
    _orbitPoints.value = value;
    notifyListeners();
  }

  /// Orbit direction (true = clockwise, false = counter-clockwise)
  final _orbitClockwise = ValueNotifier<bool>(true);
  bool get orbitClockwise => _orbitClockwise.value;
  set orbitClockwise(bool value) {
    _orbitClockwise.value = value;
    notifyListeners();
  }

  /// Whether to face POI during orbit
  final _orbitFacePoi = ValueNotifier<bool>(true);
  bool get orbitFacePoi => _orbitFacePoi.value;
  set orbitFacePoi(bool value) {
    _orbitFacePoi.value = value;
    notifyListeners();
  }

  /// Whether POI selection is active
  final _selectingPoi = ValueNotifier<bool>(false);
  bool get selectingPoi => _selectingPoi.value;
  set selectingPoi(bool value) {
    _selectingPoi.value = value;
    notifyListeners();
  }

  /// Facade mission mode
  final _facadeMode = ValueNotifier<bool>(false);
  bool get facadeMode => _facadeMode.value;
  set facadeMode(bool value) {
    _facadeMode.value = value;
    notifyListeners();
  }

  /// Facade line points
  final _facadeLine = ValueNotifier<List<LatLng>>([]);
  List<LatLng> get facadeLine => _facadeLine.value;
  set facadeLine(List<LatLng> value) {
    _facadeLine.value = value;
    notifyListeners();
  }

  /// Facade height in meters
  final _facadeHeight = ValueNotifier<int>(30);
  int get facadeHeight => _facadeHeight.value;
  set facadeHeight(int value) {
    _facadeHeight.value = value;
    notifyListeners();
  }

  /// Distance from building in meters
  final _facadeDistanceFromBuilding = ValueNotifier<double>(20.0);
  double get facadeDistanceFromBuilding => _facadeDistanceFromBuilding.value;
  set facadeDistanceFromBuilding(double value) {
    _facadeDistanceFromBuilding.value = value;
    notifyListeners();
  }

  /// Facade front overlap percentage
  final _facadeFrontOverlap = ValueNotifier<int>(80);
  int get facadeFrontOverlap => _facadeFrontOverlap.value;
  set facadeFrontOverlap(int value) {
    _facadeFrontOverlap.value = value;
    notifyListeners();
  }

  /// Facade side overlap percentage
  final _facadeSideOverlap = ValueNotifier<int>(60);
  int get facadeSideOverlap => _facadeSideOverlap.value;
  set facadeSideOverlap(int value) {
    _facadeSideOverlap.value = value;
    notifyListeners();
  }

  /// Facade camera pitch in degrees
  final _facadeCameraPitch = ValueNotifier<int>(-45);
  int get facadeCameraPitch => _facadeCameraPitch.value;
  set facadeCameraPitch(int value) {
    _facadeCameraPitch.value = value;
    notifyListeners();
  }

  void notify() => notifyListeners();
}