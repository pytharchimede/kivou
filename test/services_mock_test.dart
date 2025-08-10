import 'package:flutter_test/flutter_test.dart';
import 'package:kivou_app/utils/mock_data.dart';

void main() {
  test('Mock providers non vide', () {
    expect(MockData.providers.isNotEmpty, true);
  });
}
