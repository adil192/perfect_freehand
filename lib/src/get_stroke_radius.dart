double defaultEasing(double t) => t;

/// Compute a radius based on the pressure.
double getStrokeRadius(
    {required double size,
    required double thinning,
    required double pressure,
    double Function(double) easing = defaultEasing}) {
  return size * easing(0.5 - thinning * (0.5 - pressure));
}
