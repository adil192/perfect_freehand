import 'package:perfect_freehand/src/types.dart';

@Deprecated("Use 'PointVector' instead")
class Point extends PointVector {
  @Deprecated("Use 'pressure' instead")
  double get p => pressure ?? 0.5;

  const Point(
    super.x,
    super.y, [
    super.pressure,
  ]);
}
