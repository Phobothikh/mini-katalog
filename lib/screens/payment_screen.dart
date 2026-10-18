import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../checkout/locations.dart';
import '../checkout/validators.dart';
import '../models/product.dart';
import '../state/cart_controller.dart';
import '../theme/app_colors.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.items});

  final List<CartItem> items;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _deliveryName = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _cardName = TextEditingController();
  final _cardNumber = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();

  String _addressTitle = addressTitles.first;
  String? _city;
  String? _district;
  bool _attempted = false;

  double get _total {
    return widget.items.fold<double>(0, (sum, item) => sum + item.lineTotal);
  }

  @override
  void dispose() {
    _deliveryName.dispose();
    _phone.dispose();
    _address.dispose();
    _cardName.dispose();
    _cardNumber.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  Map<String, String> get _errors {
    if (!_attempted) {
      return const {};
    }
    final errors = <String, String>{};
    void put(String key, String? message) {
      if (message != null) {
        errors[key] = message;
      }
    }

    put('deliveryName', deliveryNameError(_deliveryName.text));
    put('phone', phoneError(_phone.text));
    put('city', cityError(_city));
    put('district', districtError(_city, _district));
    put('address', addressError(_address.text));
    put('cardName', cardNameError(_cardName.text));
    put('cardNumber', cardNumberError(_cardNumber.text));
    put('expiry', expiryError(_expiry.text));
    put('cvv', cvvError(_cvv.text));
    return errors;
  }

  @override
  Widget build(BuildContext context) {
    final total = formatTry(_total);
    final errors = _errors;
    final districts = _city == null ? const <String>[] : districtsOf(_city!);

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: AppColors.text,
                ),
                label: const Text(
                  'Ödeme',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _Section(
                    title: 'Sipariş özeti',
                    child: Column(
                      children: [
                        for (final item in widget.items)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.product.name} x${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(formatTry(item.lineTotal)),
                              ],
                            ),
                          ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Toplam',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              total,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.price,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: 'Teslimat adresi',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final title in addressTitles)
                              ChoiceChip(
                                label: Text(title),
                                selected: _addressTitle == title,
                                onSelected: (_) =>
                                    setState(() => _addressTitle = title),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          controller: _deliveryName,
                          label: 'Ad soyad',
                          errorText: errors['deliveryName'],
                          textInputAction: TextInputAction.next,
                          onChanged: _refresh,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          controller: _phone,
                          label: 'Cep telefonu',
                          hint: '05xx xxx xx xx',
                          errorText: errors['phone'],
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                            const _PhoneFormatter(),
                          ],
                          onChanged: _refresh,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: const ValueKey('city-dropdown'),
                          initialValue: _city,
                          isExpanded: true,
                          decoration: _dropdownDecoration(
                            'İl',
                            errors['city'],
                          ),
                          items: [
                            for (final city in deliveryCities.keys)
                              DropdownMenuItem(value: city, child: Text(city)),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _city = value;
                              _district = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: const ValueKey('district-dropdown'),
                          initialValue: _district,
                          isExpanded: true,
                          decoration: _dropdownDecoration(
                            'İlçe',
                            errors['district'],
                          ),
                          items: [
                            for (final district in districts)
                              DropdownMenuItem(
                                value: district,
                                child: Text(district),
                              ),
                          ],
                          onChanged: districts.isEmpty
                              ? null
                              : (value) => setState(() => _district = value),
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          controller: _address,
                          label: 'Açık adres',
                          hint: 'Mahalle, sokak, no',
                          errorText: errors['address'],
                          onChanged: _refresh,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: 'Kart bilgileri',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Eğitim simülasyonu. Karttan çekim yapılmaz, bilgi kaydedilmez. ATM şifresi isteme.',
                          style: TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                        const SizedBox(height: 14),
                        _Field(
                          controller: _cardName,
                          label: 'Kart üzerindeki isim',
                          errorText: errors['cardName'],
                          textInputAction: TextInputAction.next,
                          onChanged: _refresh,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          controller: _cardNumber,
                          label: 'Kart numarası',
                          hint: 'ACCT-000015',
                          errorText: errors['cardNumber'],
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                            const _CardNumberFormatter(),
                          ],
                          onChanged: _refresh,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _Field(
                                controller: _expiry,
                                label: 'Son kullanma tarihi',
                                hint: 'AA/YY',
                                errorText: errors['expiry'],
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                  const _ExpiryFormatter(),
                                ],
                                onChanged: _refresh,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _Field(
                                controller: _cvv,
                                label: 'Kart şifresi',
                                hint: 'Arkadaki 3 hane',
                                errorText: errors['cvv'],
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(3),
                                ],
                                onChanged: _refresh,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  key: const ValueKey('pay-button'),
                  onPressed: _pay,
                  child: Text('$total öde'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refresh(String _) {
    if (_attempted) {
      setState(() {});
    }
  }

  void _pay() {
    setState(() => _attempted = true);
    if (_errors.isNotEmpty) {
      return;
    }

    CartScope.of(context).removePaid(widget.items.map((item) => item.product.id));
    final total = formatTry(_total);
    final place =
        '$_addressTitle, $_district / $_city, ${_address.text.trim()}';
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ödeme tamamlandı'),
          content: Text(
            'Siparişin alındı. Toplam $total.\n'
            'Teslimat: $place\n\n'
            'Bu bir eğitim simülasyonuydu. Kartından çekim yapılmadı.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }
}

InputDecoration _dropdownDecoration(String label, String? error) {
  return InputDecoration(
    labelText: label,
    errorText: error,
    errorMaxLines: 3,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.inputFormatters,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        errorMaxLines: 3,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  const _CardNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  const _ExpiryFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    final text = digits.length <= 2
        ? digits
        : '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _PhoneFormatter extends TextInputFormatter {
  const _PhoneFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length && i < 11; i++) {
      if (i == 4 || i == 7 || i == 9) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
