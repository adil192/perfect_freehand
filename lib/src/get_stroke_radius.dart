import 'package:perfect_freehand/src/types.dart';

/// Compute a radius based on the pressure.
double getStrokeRadius(
    {required double size,
    required double thinning,
    required double pressure,
    double Function(double) easing = StrokeEasings.identity}) {
  return size * easing(0.5 - thinning * (0.5 - pressure));
}
