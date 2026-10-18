import 'package:flutter_test/flutter_test.dart';
import 'package:mini_katalog/models/product.dart';
import 'package:mini_katalog/state/cart_controller.dart';

void main() {
  const product = Product(
    id: 20,
    name: 'HomePod Mini',
    tagline: 'Color-pop.',
    description: 'Small speaker.',
    price: '\$99',
    currency: 'USD',
    imageUrl: 'https://wantapi.com/assets/images/homepod_mini.png',
    specs: {'size': '3.3 inches', 'audio': '360-degree', 'colors': '5 colors'},
  );

  test('fromJson and toJson keep the product fields', () {
    final parsed = Product.fromJson(product.toJson());
    expect(parsed.name, 'HomePod Mini');
    expect(parsed.specs['size'], '3.3 inches');
    expect(parsed.imageAsset, 'assets/images/homepod_mini.png');
    expect(parsed.category, 'Audio');
    expect(
      Product.fromJson({
        'id': 1,
        'name': 'iPhone 15 Pro',
        'image': 'https://wantapi.com/assets/images/iphone.png',
      }).category,
      'iPhone',
    );
    expect(
      Product.fromJson({
        'id': 21,
        'name': 'Samsung Galaxy S24',
        'image': 'assets/images/galaxy_s24.png',
      }).category,
      'Samsung',
    );
    expect(
      Product.fromJson({
        'id': 26,
        'name': 'Redmi Note 13',
        'image': 'assets/images/redmi_note_13.png',
      }).category,
      'Xiaomi',
    );
    expect(parsed.toJson()['price'], '\$99');
    expect(
      Product.fromJson({
        'id': 31,
        'name': 'Basic Tişört',
        'image': 'assets/images/basic_tisort.png',
      }).department,
      'Giyim',
    );
    expect(product.department, 'Ses');
  });

  test('cart add, select, and total are a local simulation', () {
    final cart = CartController();
    cart.add(product);
    cart.add(product);
    expect(cart.count, 2);
    expect(formatTry(cart.selectedTotal), '198 TL');

    cart.changeQuantity(product.id, -1);
    expect(cart.count, 1);
    expect(formatUsd(cart.selectedTotal), '\$99');

    cart.toggleSelected(product.id);
    expect(cart.selectedItems, isEmpty);

    cart.removePaid([product.id]);
    expect(cart.count, 0);
    cart.dispose();
  });
}
