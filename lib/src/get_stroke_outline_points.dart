import 'dart:math';
import 'dart:ui';

import 'package:perfect_freehand/src/get_stroke_radius.dart';
import 'package:perfect_freehand/src/types.dart';

// This is the rate of change for simulated pressure. It could be an option.
const rateOfPressureChange = 0.275;

// Browser strokes seem to be off if PI is regular, a tiny offset seems to fix it
const fixedPi = pi + 0.0001;

/// Get an array of points representing the outline of a stroke.
List<Offset> getStrokeOutlinePoints({
  required List<StrokePoint> points,
  StrokeOptions? options,
}) {
  final size = options?.size ?? 16;
  final smoothing = options?.smoothing ?? 0.5;
  final thinning = options?.thinning ?? 0.5;
  final simulatePressure = options?.simulatePressure ?? true;
  final easing = options?.easing ?? StrokeEasings.identity;
  final start = options?.start ?? StrokeEndOptions();
  final end = options?.end ?? StrokeEndOptions();
  final isComplete = options?.isComplete ?? false;

  final capStart = start.cap ?? true;
  final taperStartEase = start.easing ?? StrokeEasings.easeInOut;
  final capEnd = end.cap ?? true;
  final taperEndEase = end.easing ?? StrokeEasings.easeOutCubic;

  // We can't do anything with an empty array or a stroke with negative size.
  if (points.isEmpty || size <= 0) return [];

  // The total length of the line.
  final totalLength = points.last.runningLength;

  final taperStart = (start.taperEnabled ?? false)
      ? start.customTaper ?? max(size, totalLength)
      : 0.0;
  final taperEnd = (end.taperEnabled ?? false)
      ? end.customTaper ?? max(size, totalLength)
      : 0.0;

  /// The minimum allowed distance between points (squared)
  final minDistance = pow(size * smoothing, 2);

  // Our collected left and right points
  final leftPoints = <Offset>[];
  final rightPoints = <Offset>[];

  // Previous pressure.
  // We start with average of first five pressures,
  // in order to prevent fat starts for every line.
  // Drawn lines almost always start slow!
  final prevPressure = () {
    double acc = points.first.pressure;
    for (final curr in points.sublist(0, 10)) {
      final double pressure;
      if (simulatePressure) {
        // Speed of change - how fast should the pressure be changing?
        final sp = min(1, curr.distance / size);
        // Rate of change - how much of a change is there?
        final rp = min(1, 1 - sp);
        // Accelerate the pressure
        pressure = min(1, acc + (rp - acc) * (sp * rateOfPressureChange));
      } else {
        pressure = curr.pressure;
      }

      acc = (acc + pressure) / 2;
    }
    return acc;
  }();

  // The current radius
  var radius = getStrokeRadius(
    size: size,
    thinning: thinning,
    pressure: points.last.pressure,
    easing: easing,
  );

  // The radius of the first saved point
  double? firstRadius;

  // Previous vector
  var prevVector = points.first.vector;

  // Previous left and right points
  var pl = points.first.point;
  var pr = pl;

  // Temporary left and right points
  var tl = pl;
  var tr = pr;

  // Keep track of whether the previous point is a sharp corner
  // ... so that we don't detect the same corner twice
  var isPrevPointSharpCorner = false;

  // var short = true

  /**
   * Find the outline's left and right points
   * 
   * Iterating through the points and populate the rightPts and leftPts arrays,
   * skipping the first and last points, which will get caps later on.
   */

  for (int i = 0; i < points.length; ++i) {
    var pressure = points[i].pressure;
    final point = points[i].point;
    final vector = points[i].vector;
    final distance = points[i].distance;
    final runningLength = points[i].runningLength;

    // Removes noise from the end of the line
    if (i < points.length - 1 && totalLength - runningLength < size) {
      continue;
    }

    /**
     * Calculate the radius
     * 
     * If not thinning, the current point's radius will be half the size; or
     * otherwise, the size will be based on the current (real or simulated)
     * pressure.
     */

    if (thinning != 0) {
      if (simulatePressure) {
        // If we're simulating pressure, then do so based on the distance
        // between the current point and the previous point, and the size
        // of the stroke. Otherwise, use the input pressure.
        final sp = min(1, distance / size);
        final rp = min(1, 1 - sp);
        pressure = min(1,
            prevPressure + (rp - prevPressure) * (sp * rateOfPressureChange));
      }

      radius = getStrokeRadius(
        size: size,
        thinning: thinning,
        pressure: pressure,
        easing: easing,
      );
    } else {
      radius = size / 2;
    }

    firstRadius ??= radius;

    /**
     * Apply tapering
     * 
     * If the current length if within the taper distance at either the
     * start or the end, calculate the taper strengths. Apply the smaller
     * of the two taper strengths to the radius.
     */

    final ts = runningLength < taperStart
        ? taperStartEase(runningLength / taperStart)
        : 1;
    final te = totalLength - runningLength < taperEnd
        ? taperEndEase((totalLength - runningLength) / taperEnd)
        : 1;

    radius = max(0.01, radius * min(ts, te));

    // Add points to left and right

    /**
     * Handle sharp corners
     * 
     * Find the difference (dot product) between the current and next vector.
     * If the next vector is at more than a right angle to the current vector,
     * draw a cap at the current point.
     */

    final nextVector = i < points.length - 1 ? points[i + 1].vector : vector;
    final nextDpr = i < points.length - 1 ? vector.dpr(nextVector) : 1.0;
    final prevDpr = vector.dpr(prevVector);

    final isPointSharpCorner = prevDpr < 0 && !isPrevPointSharpCorner;
    final isNextPointSharpCorner = nextDpr < 0;

    if (isPointSharpCorner || isNextPointSharpCorner) {
      // It's a sharp corner. Draw a rounded cap and move on to the next point
      // Considering saving these and drawing them later? So that we can avoid
      // crossing future points.

      final offset = prevVector.perpendicular().scale(radius);

      const step = 1 / 13;
      for (double t = 0; t <= 1; t += step) {
        tl = (point - offset).rotAround(point, fixedPi * t);
        leftPoints.add(tl.toOffset());

        tr = (point + offset).rotAround(point, fixedPi * -t);
        rightPoints.add(tr.toOffset());
      }

      pl = tl;
      pr = tr;

      if (isNextPointSharpCorner) {
        isPrevPointSharpCorner = true;
      }
      continue;
    }

    isPrevPointSharpCorner = false;

    // Handle the last point
    if (i == points.length - 1) {
      final offset = vector.perpendicular().scale(radius);
      leftPoints.add((point - offset).toOffset());
      rightPoints.add((point + offset).toOffset());
      continue;
    }

    /**
     * Add regular points
     * 
     * Project points to either side of the current point, using the
     * calculated size as a distance. If a point's distance to the
     * previous point on that side is greater than the minimum distance
     * (or if the corner is kinda sharp), add the points to the side's
     * points array.
     */

    // TODO(adil192): Continue porting this
  }
}
