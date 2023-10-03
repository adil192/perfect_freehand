import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/src/get_stroke.dart';

import 'inputs/one_point.dart';

void main() {
  group('getStroke', () {
    test('gets stroke from a line with a single point', () {
      expect(getStroke(onePoint), defaultOutputOnePoint);
    });
  });
}
