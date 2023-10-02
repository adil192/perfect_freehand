import 'dart:math';
import 'dart:ui';

/// The options object for [getStroke] or [getStrokePoints].
class StrokeOptions {
  /// The base size (diameter) of the stroke.
  double? size;

  /// The effect of pressure on the stroke's size.
  double? thinning;

  /// How much to soften the stroke's edges.
  double? smoothing;

  double? streamline;

  /// An easing function to apply to each point's pressure.
  double Function(double)? easing;

  /// Whether to simulate pressure based on velocity.
  bool? simulatePressure;

  /// Cap, taper, and easing for the start of the line.
  StrokeEndOptions? start;

  /// Cap, taper, and easing for the end of the line.
  StrokeEndOptions? end;

  /// Whether to handle the points as a completed stroke.
  bool? isComplete;

  StrokeOptions({
    this.size,
    this.thinning,
    this.smoothing,
    this.streamline,
    this.easing,
    this.simulatePressure,
    this.start,
    this.end,
    this.isComplete,
  });
}

class StrokeEasings {
  /// Identity function.
  /// Returns the input value.
  static double identity(double t) => t;

  /// Ease-in-out function.
  /// Used for the taper start.
  static double easeInOut(double t) => t * (2 - t);

  /// Ease-out-cubic function.
  /// Used for the taper end.
  static double easeOutCubic(double t) => --t * t * t + 1;
}

/// Stroke options for the start/end of the line.
class StrokeEndOptions {
  bool? cap;
  bool? taperEnabled;
  double? customTaper;
  double Function(double)? easing;

  StrokeEndOptions({
    this.cap,
    this.taperEnabled,
    this.customTaper,
    this.easing,
  }) {
    if (customTaper != null) {
      taperEnabled = true;
    }
  }
}

/// The points returned by [getStrokePoints]
/// and the input for [getStrokeOutlinePoints].
class StrokePoint {
  /// The adjusted point.
  PointVector point;

  /// The input pressure.
  double pressure;

  /// The distance between the current point and the previous point.
  double distance;

  /// The vector from the current point to the previous point.
  PointVector vector;

  /// The total distance so far.
  double runningLength;

  StrokePoint({
    required this.point,
    required this.pressure,
    required this.distance,
    required this.vector,
    required this.runningLength,
  });
}

class PointVector {
  final double x;
  final double y;
  final double? pressure;

  const PointVector({
    required this.x,
    required this.y,
    this.pressure,
  });

  PointVector.fromOffset({
    required Offset offset,
    this.pressure,
  })  : x = offset.dx,
        y = offset.dy;

  PointVector copyWith({
    double? x,
    double? y,
    double? pressure,
  }) =>
      PointVector(
        x: x ?? this.x,
        y: y ?? this.y,
        pressure: pressure ?? this.pressure,
      );

  PointVector lerp(
    double t,
    PointVector other,
  ) {
    assert(t >= 0.0 && t <= 1.0);
    assert(pressure != null);
    assert(other.pressure != null);

    return PointVector(
      x: lerpDouble(x, other.x, t)!,
      y: lerpDouble(y, other.y, t)!,
      pressure: lerpDouble(pressure, other.pressure, t) ?? pressure ?? 0.5,
    );
  }

  /// Rotate a vector around another vector by [r] radians
  PointVector rotAround(PointVector center, double r) {
    final s = sin(r);
    final c = cos(r);

    final px = x - center.x;
    final py = y - center.y;

    final nx = px * c - py * s;
    final ny = px * s + py * c;

    return PointVector(
      x: nx + center.x,
      y: ny + center.y,
      pressure: pressure,
    );
  }

  double distanceTo(PointVector point) {
    final dx = x - point.x;
    final dy = y - point.y;
    return sqrt(dx * dx + dy * dy);
  }

  PointVector unitVectorTo(PointVector other) {
    final dx = other.x - x;
    final dy = other.y - y;
    final distance = sqrt(dx * dx + dy * dy);
    return PointVector(
      x: dx / distance,
      y: dy / distance,
    );
  }

  /// Dot product
  double dpr(PointVector other) {
    return x * other.x + y * other.y;
  }

  /// Perpendicular rotation of the vector
  PointVector perpendicular() {
    return PointVector(
      x: y,
      y: -x,
    );
  }

  PointVector scale(double scale) {
    return PointVector(
      x: x * scale,
      y: y * scale,
    );
  }

  Offset toOffset() => Offset(x, y);

  PointVector operator +(PointVector other) {
    return PointVector(
      x: x + other.x,
      y: y + other.y,
      pressure: pressure ?? other.pressure,
    );
  }

  PointVector operator -(PointVector other) {
    return PointVector(
      x: x - other.x,
      y: y - other.y,
      pressure: other.pressure ?? pressure,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PointVector &&
      x == other.x &&
      y == other.y &&
      pressure == other.pressure;

  @override
  int get hashCode => Object.hash(x, y, pressure);
}
