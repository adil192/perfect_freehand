import 'package:perfect_freehand/src/types.dart';

@Deprecated("Use 'PointVector' instead")
class Point extends PointVector {
  @Deprecated("Use 'pressure' instead")
  double get p => pressure ?? 0.5;

  const Point(
    double x,
    double y, [
    double? pressure,
  ]) : super(
          x: x,
          y: y,
          pressure: pressure,
        );
}
