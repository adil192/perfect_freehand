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

/// Stroke options for the start/end of the line.
class StrokeEndOptions {
  bool? cap;
  double? taper;
  double Function(double)? easing;

  StrokeEndOptions({
    this.cap,
    this.taper,
    this.easing,
  });
}

/// The points returned by [getStrokePoints]
/// and the input for [getStrokeOutlinePoints].
class StrokePoint {
  PointVector point;
  double pressure;
  double distance;
  PointVector vector;
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
  double x;
  double y;
  double? pressure;

  PointVector({
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
}
