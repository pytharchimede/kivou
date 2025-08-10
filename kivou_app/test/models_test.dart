import 'package:flutter_test/flutter_test.dart';
import 'package:kivou_app/models/booking.dart';

void main() {
  test('Booking formattedDuration', () {
    final b1 = Booking(
      id: 'b',
      userId: 'u',
      providerId: 'p',
      serviceCategory: 'Test',
      serviceDescription: 'Desc',
      scheduledAt: DateTime(2025, 1, 1, 9),
      duration: 2.5,
      totalPrice: 10,
      status: BookingStatus.pending,
      createdAt: DateTime(2025, 1, 1),
    );
    expect(b1.formattedDuration, '2h30');
  });
}
