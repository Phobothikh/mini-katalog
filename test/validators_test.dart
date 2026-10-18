import 'package:flutter_test/flutter_test.dart';
import 'package:mini_katalog/checkout/validators.dart';

void main() {
  final now = DateTime(2026, 10, 17);

  test('expiry rejects impossible and expired dates', () {
    expect(expiryError('31/31', now: now), contains('31/31'));
    expect(expiryError('00/30', now: now), contains('01-12'));
    expect(expiryError('13/30', now: now), contains('01-12'));
    expect(expiryError('09/26', now: now), contains('geçmiş'));
    expect(expiryError('10/26', now: now), isNull);
    expect(expiryError('12/28', now: now), isNull);
  });

  test('cvv rejects trial codes and short values', () {
    expect(cvvError('12'), contains('3 haneli'));
    expect(cvvError('000'), contains('deneme'));
    expect(cvvError('123'), contains('deneme'));
    expect(cvvError('258'), isNull);
  });

  test('card number uses the checksum', () {
    expect(cardNumberError('4242424242424242'), isNull);
    expect(cardNumberError('4242 4242 4242 4242'), isNull);
    expect(cardNumberError('4242424242424241'), contains('geçersiz'));
    expect(cardNumberError('1234'), contains('16 hane'));
  });

  test('delivery fields reject incomplete address data', () {
    expect(deliveryNameError('Ali'), isNotNull);
    expect(deliveryNameError('Ayşe Yılmaz'), isNull);
    expect(phoneError('123'), isNotNull);
    expect(phoneError('0532 123 45 67'), isNull);
    expect(cityError(null), isNotNull);
    expect(districtError('İstanbul', 'Kadıköy'), isNull);
    expect(districtError('İstanbul', 'Kadikoy'), isNotNull);
    expect(addressError('kisa'), isNotNull);
    expect(addressError('Moda Caddesi No 10'), isNull);
  });
}
