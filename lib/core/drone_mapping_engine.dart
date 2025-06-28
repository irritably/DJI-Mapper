import 'dart:math';

import 'package:latlong2/latlong.dart';

class DroneMappingEngine {
  /// Altitude in meters
  final double altitude;

  /// Forward overlap in percentage
  final double forwardOverlap;

  /// Side overlap in percentage
  final double sideOverlap;

  /// Sensor width in mm
  final double sensorWidth;

  /// Sensor height in mm
  final double sensorHeight;

  /// Focal length in mm
  final double focalLength;

  /// Image width in pixels
  final int imageWidth;

  /// Image height in pixels
  final int imageHeight;

  /// Angle of the drone in degrees
  final double angle;

  DroneMappingEngine({
    required this.altitude,
    required this.forwardOverlap,
    required this.sideOverlap,
    required this.sensorWidth,
    required this.sensorHeight,
    required this.focalLength,
    required this.imageWidth,
    required this.imageHeight,
    required this.angle,
  });

  double get gsdX => (altitude * sensorWidth) / (imageWidth * focalLength);
  double get gsdY => (altitude * sensorHeight) / (imageHeight * focalLength);

  double get footprintWidth => gsdX * imageWidth;
  double get footprintHeight => gsdY * imageHeight;

  double get effectiveFootprintWidth => footprintWidth * (1 - sideOverlap);
  double get effectiveFootprintHeight => footprintHeight * (1 - forwardOverlap);

  double get flightLineSpacing => footprintWidth * (1 - sideOverlap);
  double get pathSpacing => footprintHeight * (1 - forwardOverlap);

  // Spacing for horizontal lines
  double get horizontalLineSpacing => footprintHeight * (1 - sideOverlap);      // Y spacing (cross-track)
  double get horizontalWaypointSpacing => footprintWidth * (1 - forwardOverlap); // X spacing (along-track)

  // Convert LatLng to local coordinate system (in meters)
  static List<Point> _latLngToMeters(List<LatLng> polygon) {
    var origin = polygon[0];
    double originLat = origin.latitude;
    double originLng = origin.longitude;
    return polygon.map((latLng) {
      double x = (latLng.longitude - originLng) *
          (40075000 * cos((originLat * pi) / 180) / 360);
      double y = (latLng.latitude - originLat) * (40075000 / 360);
      return Point(x, y);
    }).toList();
  }

  // Convert local coordinates (in meters) back to LatLng
  static List<LatLng> _metersToLatLng(List<Point> points, LatLng origin) {
    double originLat = origin.latitude;
    double originLng = origin.longitude;
    return points.map((point) {
      double lat = originLat + (point.y / (40075000 / 360));
      double lng = originLng +
          (point.x / (40075000 * cos((originLat * pi) / 180) / 360));
      return LatLng(lat, lng);
    }).toList();
  }

  // Rotate a point around the origin by a given angle
  static Point _rotatePoint(Point point, double angle) {
    double radians = angle * (pi / 180);
    double cosTheta = cos(radians);
    double sinTheta = sin(radians);
    double x = point.x * cosTheta - point.y * sinTheta;
    double y = point.x * sinTheta + point.y * cosTheta;
    return Point(x, y);
  }

  // Rotate a list of points around the origin by a given angle
  static List<Point> _rotatePolygon(List<Point> polygon, double angle) {
    return polygon.map((point) => _rotatePoint(point, angle)).toList();
  }

  // Check if a point is inside a polygon
  static bool _isPointInPolygon(Point point, List<Point> polygon) {
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (((polygon[i].y > point.y) != (polygon[j].y > point.y)) &&
          (point.x <
              (polygon[j].x - polygon[i].x) *
                      (point.y - polygon[i].y) /
                      (polygon[j].y - polygon[i].y) +
                  polygon[i].x)) {
        inside = !inside;
      }
    }
    return inside;
  }

  // Calculate the area of a polygon using the Shoelace formula
  static double calculateArea(List<LatLng> polygon) {
    var localPolygon = _latLngToMeters(polygon);
    double area = 0.0;
    for (int i = 0; i < localPolygon.length - 1; i++) {
      area += localPolygon[i].x * localPolygon[i + 1].y -
          localPolygon[i + 1].x * localPolygon[i].y;
    }
    area += localPolygon.last.x * localPolygon.first.y -
        localPolygon.first.x * localPolygon.last.y;
    return area.abs() / 2.0;
  }

  // Generate waypoints within the polygon in a boustrophedon pattern
  List<LatLng> generateWaypoints(List<LatLng> polygon, bool createCameraPoints, [bool fillGrid = false]) {
    var localPolygon = _latLngToMeters(polygon);
    var rotatedPolygon = _rotatePolygon(localPolygon, angle);
    var origin = polygon[0];

    num minX = rotatedPolygon.map((p) => p.x).reduce(min);
    num maxX = rotatedPolygon.map((p) => p.x).reduce(max);
    num minY = rotatedPolygon.map((p) => p.y).reduce(min);
    num maxY = rotatedPolygon.map((p) => p.y).reduce(max);

    List<Point> waypoints = [];
    bool reverse = false;

    for (num y = minY; y <= maxY; y += horizontalLineSpacing) {
      List<Point> line = [];
      if (createCameraPoints) {
        for (num x = minX; x <= maxX; x += horizontalWaypointSpacing) {
          Point p = Point(x, y);
          if (_isPointInPolygon(p, rotatedPolygon)) {
            line.add(p);
          }
        }
        if (line.isNotEmpty) {
          Point lastInLine = line.last;
          if ((maxX - lastInLine.x).abs() > 1e-6) {
            Point candidate = Point(maxX, y);
            if (_isPointInPolygon(candidate, rotatedPolygon)) {
              line.add(candidate);
            }
          }
        }
      } else {
        Point? firstPoint;
        Point? lastPoint;
        for (num x = minX; x <= maxX; x += horizontalWaypointSpacing) {
          Point p = Point(x, y);
          if (_isPointInPolygon(p, rotatedPolygon)) {
            firstPoint ??= p;
            lastPoint = p;
          }
        }
        if (firstPoint != null) {
          if (lastPoint != null && (maxX - lastPoint.x).abs() > 1e-6) {
            Point candidate = Point(maxX, y);
            if (_isPointInPolygon(candidate, rotatedPolygon)) {
              lastPoint = candidate;
            }
          }
          line.add(firstPoint);
          if (lastPoint != null && lastPoint != firstPoint) {
            line.add(lastPoint);
          }
        }
      }
      if (reverse) {
        line = line.reversed.toList();
      }
      waypoints.addAll(line);
      reverse = !reverse;
    }

    Point lastHorizontalPoint = waypoints.isNotEmpty ? waypoints.last : Point(minX, minY);

    if (fillGrid && waypoints.isNotEmpty) {
        num minHorizontalX = waypoints.isNotEmpty ? waypoints.map((p) => p.x).reduce(min) : minX;
        num maxHorizontalX = waypoints.isNotEmpty ? waypoints.map((p) => p.x).reduce(max) : maxX;
        num minHorizontalY = waypoints.isNotEmpty ? waypoints.map((p) => p.y).reduce(min) : minY;
        num maxHorizontalY = waypoints.isNotEmpty ? waypoints.map((p) => p.y).reduce(max) : maxY;

        List<Point> verticalWaypoints = generateVerticalWaypoints(rotatedPolygon, createCameraPoints, lastHorizontalPoint, minHorizontalX, maxHorizontalX, minHorizontalY, maxHorizontalY);
        waypoints.addAll(verticalWaypoints);
    }

    // Rotate the combined waypoints back to the original orientation.
    var rotatedWaypointsBack = _rotatePolygon(waypoints, -angle);
    return _metersToLatLng(rotatedWaypointsBack, origin);
  }

  // Generates a vertical boustrophedon pattern to fill the polygon.
  List<Point> generateVerticalWaypoints(List<Point> polygon, bool createCameraPoints, Point lastHorizontal, num minHorizontalX, num maxHorizontalX, num minHorizontalY, num maxHorizontalY) {
    List<Point> verticalWaypoints = [];
    num verticalLineSpacing = horizontalLineSpacing; //footprintWidth * (1 - sideOverlap);
    num verticalWaypointSpacing = footprintHeight * (1 - forwardOverlap);
    num offset = verticalWaypointSpacing * 0.1; // e.g., 10% of vertical spacing

    List<num> verticalYCoords = [];
    num adjustedMinY = minHorizontalY - verticalWaypointSpacing / 2 - offset;
    for (num y = adjustedMinY; y <= maxHorizontalY + verticalWaypointSpacing / 2; y += verticalWaypointSpacing) {
      verticalYCoords.add(y);
    }

    // Calculate potential starting points on left and right edges
    num xLeft = minHorizontalX + verticalLineSpacing / 2;
    List<num> yLeft = verticalYCoords.where((y) => _isPointInPolygon(Point(xLeft, y), polygon)).toList();
    num minDistLeft = double.infinity;
    num distBottomLeft = double.infinity;
    num distTopLeft = double.infinity;
    if (yLeft.isNotEmpty) {
      num yBottomLeft = yLeft.first;
      num yTopLeft = yLeft.last;
      distBottomLeft = sqrt(pow(xLeft - lastHorizontal.x, 2) + pow(yBottomLeft - lastHorizontal.y, 2));
      distTopLeft = sqrt(pow(xLeft - lastHorizontal.x, 2) + pow(yTopLeft - lastHorizontal.y, 2));
      minDistLeft = min(distBottomLeft, distTopLeft);
    }

    num xRight = maxHorizontalX - verticalLineSpacing / 2;
    List<num> yRight = verticalYCoords.where((y) => _isPointInPolygon(Point(xRight, y), polygon)).toList();
    num minDistRight = double.infinity;
    num distBottomRight = double.infinity;
    num distTopRight = double.infinity;
    if (yRight.isNotEmpty) {
      num yBottomRight = yRight.first;
      num yTopRight = yRight.last;
      distBottomRight = sqrt(pow(xRight - lastHorizontal.x, 2) + pow(yBottomRight - lastHorizontal.y, 2));
      distTopRight = sqrt(pow(xRight - lastHorizontal.x, 2) + pow(yTopRight - lastHorizontal.y, 2));
      minDistRight = min(distBottomRight, distTopRight);
    }

    // Determine starting X, direction, and initial reverse flag
    num startX;
    num deltaX;
    bool reverse;
    if (minDistLeft < minDistRight) {
      startX = xLeft;
      deltaX = verticalLineSpacing; // Move right
      reverse = distTopLeft < distBottomLeft; // True: top-to-bottom, False: bottom-to-top
    } else {
      startX = xRight;
      deltaX = -verticalLineSpacing; // Move left
      reverse = distTopRight < distBottomRight; // True: top-to-bottom, False: bottom-to-top
    }

    // Generate vertical waypoints with boustrophedon pattern
    bool condition(num x) => deltaX > 0 ? x <= maxHorizontalX + verticalLineSpacing / 2 : x >= minHorizontalX - verticalLineSpacing / 2;

    for (num x = startX; condition(x); x += deltaX) {
      List<Point> column = [];
      for (num y in verticalYCoords) {
        Point p = Point(x, y);
        if (_isPointInPolygon(p, polygon)) {
          column.add(p);
        }
      }
      if (column.isEmpty) continue;

      if (createCameraPoints) {
        if (reverse) column = column.reversed.toList();
        verticalWaypoints.addAll(column);
      } else {
        if (column.isNotEmpty) {
          Point firstPoint = column.first;
          Point lastPoint = column.last;
          if (reverse) {
            verticalWaypoints.add(lastPoint);
            if (lastPoint != firstPoint) {
              verticalWaypoints.add(firstPoint);
            }
          } else {
            verticalWaypoints.add(firstPoint);
            if (firstPoint != lastPoint) {
              verticalWaypoints.add(lastPoint);
            }
          }
        }
      }
      reverse = !reverse;
    }

    return verticalWaypoints;
  }

  /// Generate facade waypoints along a building facade
  static List<LatLng> generateFacadeWaypoints({
    required List<LatLng> facadeLine,
    required double altitude,
    required int facadeHeight,
    required double distanceFromBuilding,
    required double frontOverlap,
    required double sideOverlap,
    required double sensorWidth,
    required double sensorHeight,
    required double focalLength,
    required int imageWidth,
    required int imageHeight,
    required bool createCameraPoints,
  }) {
    if (facadeLine.length < 2) return [];

    // Calculate GSD and footprint
    double gsdX = (altitude * sensorWidth) / (imageWidth * focalLength);
    double gsdY = (altitude * sensorHeight) / (imageHeight * focalLength);
    double footprintWidth = gsdX * imageWidth;
    double footprintHeight = gsdY * imageHeight;

    // Calculate spacing between waypoints
    double horizontalSpacing = footprintWidth * (1 - frontOverlap / 100);
    double verticalSpacing = footprintHeight * (1 - sideOverlap / 100);

    // Calculate number of vertical levels needed
    int numLevels = (facadeHeight / verticalSpacing).ceil();

    List<LatLng> waypoints = [];
    
    // Convert facade line to local coordinates
    var localFacadeLine = _latLngToMeters(facadeLine);
    var origin = facadeLine[0];

    // Calculate total length of facade line
    double totalLength = 0;
    for (int i = 0; i < localFacadeLine.length - 1; i++) {
      double dx = localFacadeLine[i + 1].x - localFacadeLine[i].x;
      double dy = localFacadeLine[i + 1].y - localFacadeLine[i].y;
      totalLength += sqrt(dx * dx + dy * dy);
    }

    // Calculate number of horizontal waypoints needed
    int numHorizontalPoints = createCameraPoints 
        ? (totalLength / horizontalSpacing).ceil() + 1
        : 2; // Just start and end points if not creating camera points

    // Generate waypoints for each level
    bool reverseDirection = false;
    
    for (int level = 0; level < numLevels; level++) {
      double currentHeight = altitude + (level * verticalSpacing);
      
      List<LatLng> levelWaypoints = [];
      
      if (createCameraPoints) {
        // Generate waypoints along the facade line at regular intervals
        for (int i = 0; i < numHorizontalPoints; i++) {
          double t = i / (numHorizontalPoints - 1);
          LatLng facadePoint = _interpolateAlongFacadeLine(facadeLine, t);
          LatLng offsetPoint = _offsetPointFromFacade(facadeLine, facadePoint, distanceFromBuilding);
          levelWaypoints.add(LatLng(offsetPoint.latitude, offsetPoint.longitude));
        }
      } else {
        // Just start and end points
        LatLng startFacadePoint = facadeLine.first;
        LatLng endFacadePoint = facadeLine.last;
        LatLng startOffsetPoint = _offsetPointFromFacade(facadeLine, startFacadePoint, distanceFromBuilding);
        LatLng endOffsetPoint = _offsetPointFromFacade(facadeLine, endFacadePoint, distanceFromBuilding);
        levelWaypoints.add(startOffsetPoint);
        levelWaypoints.add(endOffsetPoint);
      }
      
      // Reverse direction for boustrophedon pattern
      if (reverseDirection) {
        levelWaypoints = levelWaypoints.reversed.toList();
      }
      
      waypoints.addAll(levelWaypoints);
      reverseDirection = !reverseDirection;
    }

    return waypoints;
  }

  /// Interpolate a point along the facade line at parameter t (0 to 1)
  static LatLng _interpolateAlongFacadeLine(List<LatLng> facadeLine, double t) {
    if (t <= 0) return facadeLine.first;
    if (t >= 1) return facadeLine.last;

    // Convert to local coordinates for easier calculation
    var localPoints = _latLngToMeters(facadeLine);
    var origin = facadeLine[0];

    // Calculate total length
    double totalLength = 0;
    List<double> segmentLengths = [];
    for (int i = 0; i < localPoints.length - 1; i++) {
      double dx = localPoints[i + 1].x - localPoints[i].x;
      double dy = localPoints[i + 1].y - localPoints[i].y;
      double length = sqrt(dx * dx + dy * dy);
      segmentLengths.add(length);
      totalLength += length;
    }

    // Find target distance along the line
    double targetDistance = t * totalLength;
    double currentDistance = 0;

    // Find which segment contains the target point
    for (int i = 0; i < segmentLengths.length; i++) {
      if (currentDistance + segmentLengths[i] >= targetDistance) {
        // Interpolate within this segment
        double segmentT = (targetDistance - currentDistance) / segmentLengths[i];
        Point p1 = localPoints[i];
        Point p2 = localPoints[i + 1];
        Point interpolated = Point(
          p1.x + (p2.x - p1.x) * segmentT,
          p1.y + (p2.y - p1.y) * segmentT,
        );
        
        // Convert back to LatLng
        var result = _metersToLatLng([interpolated], origin);
        return result[0];
      }
      currentDistance += segmentLengths[i];
    }

    return facadeLine.last;
  }

  /// Offset a point perpendicular to the facade line by the specified distance
  static LatLng _offsetPointFromFacade(List<LatLng> facadeLine, LatLng point, double distance) {
    // Find the closest segment on the facade line
    var localFacadeLine = _latLngToMeters(facadeLine);
    var localPoint = _latLngToMeters([point])[0];
    var origin = facadeLine[0];

    double minDistance = double.infinity;
    Point? closestPoint;
    Point? perpendicularDirection;

    for (int i = 0; i < localFacadeLine.length - 1; i++) {
      Point p1 = localFacadeLine[i];
      Point p2 = localFacadeLine[i + 1];
      
      // Calculate perpendicular direction (90 degrees to the right of the segment)
      double dx = p2.x - p1.x;
      double dy = p2.y - p1.y;
      double length = sqrt(dx * dx + dy * dy);
      
      if (length > 0) {
        // Normalize and rotate 90 degrees clockwise
        double perpX = dy / length;
        double perpY = -dx / length;
        
        // Calculate distance from point to line segment
        double t = ((localPoint.x - p1.x) * dx + (localPoint.y - p1.y) * dy) / (length * length);
        t = t.clamp(0.0, 1.0);
        
        Point closestOnSegment = Point(p1.x + t * dx, p1.y + t * dy);
        double distToSegment = sqrt(
          pow(localPoint.x - closestOnSegment.x, 2) + 
          pow(localPoint.y - closestOnSegment.y, 2)
        );
        
        if (distToSegment < minDistance) {
          minDistance = distToSegment;
          closestPoint = closestOnSegment;
          perpendicularDirection = Point(perpX, perpY);
        }
      }
    }

    if (closestPoint != null && perpendicularDirection != null) {
      // Offset the point by the specified distance in the perpendicular direction
      Point offsetPoint = Point(
        closestPoint.x + perpendicularDirection.x * distance,
        closestPoint.y + perpendicularDirection.y * distance,
      );
      
      var result = _metersToLatLng([offsetPoint], origin);
      return result[0];
    }

    return point; // Fallback if calculation fails
  }

  /// Generate orbit waypoints around a point of interest
  static List<LatLng> generateOrbitWaypoints({
    required LatLng poi,
    required double radiusMeters,
    required int numberOfPoints,
    required bool clockwise,
  }) {
    if (numberOfPoints < 3) {
      throw ArgumentError('Number of points must be at least 3');
    }

    List<LatLng> waypoints = [];
    
    // Earth's radius in meters
    const double earthRadius = 6371000.0;
    
    // Convert POI to radians
    double poiLatRad = poi.latitude * pi / 180;
    double poiLngRad = poi.longitude * pi / 180;
    
    // Calculate angular distance
    double angularDistance = radiusMeters / earthRadius;
    
    // Generate waypoints around the circle
    for (int i = 0; i < numberOfPoints; i++) {
      // Calculate bearing for this point
      double bearing = (2 * pi * i / numberOfPoints);
      
      // Reverse direction if counter-clockwise
      if (!clockwise) {
        bearing = 2 * pi - bearing;
      }
      
      // Calculate new position using spherical trigonometry
      double newLatRad = asin(
        sin(poiLatRad) * cos(angularDistance) +
        cos(poiLatRad) * sin(angularDistance) * cos(bearing)
      );
      
      double newLngRad = poiLngRad + atan2(
        sin(bearing) * sin(angularDistance) * cos(poiLatRad),
        cos(angularDistance) - sin(poiLatRad) * sin(newLatRad)
      );
      
      // Convert back to degrees
      double newLat = newLatRad * 180 / pi;
      double newLng = newLngRad * 180 / pi;
      
      waypoints.add(LatLng(newLat, newLng));
    }
    
    return waypoints;
  }

  static double calculateTotalDistance(List<LatLng> waypoints) {
    if (waypoints.length < 2) return 0.0;
    double totalDistance = 0.0;

    for (int i = 0; i < waypoints.length - 1; i++) {
      totalDistance += _haversineDistance(waypoints[i], waypoints[i + 1]);
    }

    return totalDistance;
  }

  static String calculateRecommendedShutterSpeed({
    required int altitude, // in meters
    required double sensorWidth, // in meters
    required double focalLength, // in meters
    required int imageWidth, // in pixels
    required double droneSpeed, // in meters per second (m/s)
  }) {
    // Calculate Ground Sampling Distance (GSD) in meters/pixel
    double gsd = (altitude * sensorWidth) / (imageWidth * focalLength);

    // Calculate recommended shutter speed to avoid motion blur (in seconds)
    double shutterSpeed = gsd / droneSpeed;

    // Find the closest standard speed
    double closest = _standardSpeeds.first;
    for (double speed in _standardSpeeds) {
      if ((shutterSpeed - speed).abs() < (shutterSpeed - closest).abs()) {
        closest = speed;
      }
    }

    return '1/${(1 / closest).toInt()}';
  }

  static double _haversineDistance(LatLng p1, LatLng p2) {
    const R = 6371e3; // Earth radius in meters
    final phi1 = p1.latitudeInRad;
    final phi2 = p2.latitudeInRad;
    final deltaPhi = (p2.latitude - p1.latitude).toRadians();
    final deltaLambda = (p2.longitude - p1.longitude).toRadians();

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c; // Distance in meters
  }

  static final List<double> _standardSpeeds = [
    1 / 16000,
    1 / 8000,
    1 / 6400,
    1 / 5000,
    1 / 4000,
    1 / 3200,
    1 / 2500,
    1 / 2000,
    1 / 1600,
    1 / 1250,
    1 / 1000,
    1 / 800,
    1 / 640,
    1 / 500,
    1 / 400,
    1 / 320,
    1 / 240,
    1 / 200,
    1 / 160,
    1 / 120,
    1 / 100,
    1 / 80,
    1 / 60,
    1 / 50,
    1 / 40,
    1 / 30,
    1 / 25,
    1 / 20,
    1 / 15,
    1 / 12.5,
    1 / 10,
    1 / 8,
    1 / 6.25,
    1 / 5,
    1 / 4,
    1 / 3,
    1 / 2,
  ];
}

extension on double {
  double toRadians() => this * pi / 180;
}