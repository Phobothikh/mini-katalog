import 'locations.dart';

final _namePattern = RegExp(
  r"^[A-Za-zÇĞİÖŞÜçğıöşü]+(?:[ '\-][A-Za-zÇĞİÖŞÜçğıöşü]+)+$",
);

const _weakCvv = {
  '000',
  '111',
  '222',
  '333',
  '444',
  '555',
  '666',
  '777',
  '888',
  '999',
  '123',
  '321',
};

String? deliveryNameError(String name) {
  if (!_namePattern.hasMatch(name.trim())) {
    return 'Ad ve soyadı birlikte yaz.';
  }
  return null;
}

String? phoneError(String phone) {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10 && digits.startsWith('5')) {
    digits = '0$digits';
  }
  if (!RegExp(r'^05\d{9}$').hasMatch(digits)) {
    return 'Cep telefonunu 05xx xxx xx xx biçiminde gir.';
  }
  return null;
}

String? cityError(String? city) {
  if (city == null || !deliveryCityKnown(city)) {
    return 'Teslimat için bir il seç.';
  }
  return null;
}

String? districtError(String? city, String? district) {
  if (cityError(city) != null) {
    return 'Önce il seç.';
  }
  final districts = districtsOf(city!);
  if (district == null || !districts.contains(district)) {
    return 'Teslimat için bir ilçe seç.';
  }
  return null;
}

String? addressError(String address) {
  final value = address.trim();
  if (value.length < 10 || !RegExp(r'\d').hasMatch(value)) {
    return 'Açık adresi sokak ve kapı numarasıyla yaz.';
  }
  return null;
}

String? cardNameError(String name) {
  if (!_namePattern.hasMatch(name.trim())) {
    return 'Kart üzerindeki adı ve soyadı yaz.';
  }
  return null;
}

String? cardNumberError(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 16) {
    return 'Kart numarası 16 hane olmalı.';
  }
  if (!_passesLuhn(digits)) {
    return 'Kart numarası geçersiz. Numarayı kontrol et.';
  }
  return null;
}

String? expiryError(String value, {DateTime? now}) {
  final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(value);
  if (match == null) {
    return 'Son kullanma tarihini AA/YY olarak gir.';
  }
  final month = int.parse(match.group(1)!);
  final year = 2000 + int.parse(match.group(2)!);
  if (month < 1 || month > 12) {
    return 'Son kullanma tarihi geçersiz. Ay 01-12 arasında olmalı, 31/31 gibi değerler kabul edilmez.';
  }
  final clock = now ?? DateTime.now();
  final lastMoment = DateTime(year, month + 1, 0, 23, 59, 59);
  if (lastMoment.isBefore(clock)) {
    return 'Kartın son kullanma tarihi geçmiş.';
  }
  final latest = DateTime(clock.year + 15, clock.month);
  if (DateTime(year, month).isAfter(latest)) {
    return 'Son kullanma tarihi çok ileri görünüyor.';
  }
  return null;
}

String? cvvError(String cvv) {
  if (!RegExp(r'^\d{3}$').hasMatch(cvv)) {
    return 'Kart güvenlik kodu 3 haneli olmalı.';
  }
  if (_weakCvv.contains(cvv)) {
    return 'Güvenlik kodu geçersiz. 000 veya 123 gibi deneme kodları kabul edilmez.';
  }
  return null;
}

bool deliveryCityKnown(String city) {
  return deliveryCities.containsKey(city);
}

List<String> districtsOf(String city) {
  return deliveryCities[city] ?? const [];
}

bool _passesLuhn(String digits) {
  var sum = 0;
  for (var i = 0; i < digits.length; i++) {
    var digit = int.parse(digits[digits.length - 1 - i]);
    if (i.isOdd) {
      digit *= 2;
      if (digit > 9) {
        digit -= 9;
      }
    }
    sum += digit;
  }
  return sum % 10 == 0;
}
