// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kivou_app/main.dart';

void main() {
  testWidgets("Affiche l'écran Splash KIVOU", (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KivouApp()));
    expect(find.text('KIVOU'), findsOneWidget);
    // Avance le temps pour simuler la navigation
    await tester.pump(const Duration(milliseconds: 950));
  });
}
