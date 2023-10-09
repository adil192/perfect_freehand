import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/src/get_stroke.dart';

import '_stroke_drawer.dart';
import 'example_inputs/one_point.dart';

void main() {
  group('getStroke', () {
    testWidgets('gets stroke from a line with a single point', (tester) async {
      final stroke = getStroke(onePoint);
      
      await tester.pumpWidget(StrokeDrawer(stroke: stroke));

      await expectLater(
        find.byType(StrokeDrawer),
        matchesGoldenFile('example_inputs/one_point.png'),
      );
    });
  });
}
