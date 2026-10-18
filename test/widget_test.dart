import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_katalog/main.dart';
import 'package:mini_katalog/models/product.dart';
import 'package:mini_katalog/screens/cart_screen.dart';
import 'package:mini_katalog/screens/payment_screen.dart';
import 'package:mini_katalog/screens/home_screen.dart';
import 'package:mini_katalog/screens/shell_screen.dart';
import 'package:mini_katalog/screens/product_detail_screen.dart';
import 'package:mini_katalog/state/cart_controller.dart';
import 'package:mini_katalog/state/favorite_controller.dart';

const _homePod = Product(
  id: 20,
  name: 'HomePod Mini',
  tagline: 'Color-pop.',
  description: 'Small speaker with room-filling sound.',
  price: '\$99',
  currency: 'USD',
  imageUrl: 'https://wantapi.com/assets/images/homepod_mini.png',
  specs: {'size': '3.3 inches', 'audio': '360-degree', 'colors': '5 colors'},
);

const _phone = Product(
  id: 1,
  name: 'iPhone 15 Pro',
  tagline: 'Titanium.',
  description: 'A titanium iPhone.',
  price: '\$999',
  currency: 'USD',
  imageUrl: 'https://wantapi.com/assets/images/iphone.png',
  specs: {'chip': 'A17 Pro'},
);

Finder _field(String label) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.labelText == label,
  );
}

Finder textWidget(String data) {
  return find.byWidgetPredicate(
    (widget) => widget is Text && widget.data == data,
  );
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('Discover screen is shown', (tester) async {
    await tester.pumpWidget(const MiniKatalogApp());
    expect(find.text('Mini Katalog'), findsWidgets);
    expect(find.text('Ana Sayfa'), findsWidgets);
    expect(find.text('Kategoriler'), findsWidgets);
    expect(find.text('Ürün veya kategori ara'), findsOneWidget);
  });

  testWidgets('search, detail, and cart simulation', (tester) async {
    final cart = CartController();
    addTearDown(cart.dispose);

    await tester.pumpWidget(
      CartScope(
        controller: cart,
        child: MaterialApp(
          home: HomeScreen(
            loadProducts: () async => const [_phone, _homePod],
          ),
          onGenerateRoute: (settings) {
            if (settings.name == ProductDetailScreen.routeName &&
                settings.arguments is Product) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) =>
                    ProductDetailScreen(product: settings.arguments! as Product),
              );
            }
            if (settings.name == CartScreen.routeName) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const CartScreen(),
              );
            }
            return null;
          },
        ),
      ),
    );
    await settle(tester);

    await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
    await settle(tester);
    expect(textWidget('Sepetin boş'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'mini');
    await settle(tester);
    expect(textWidget('HomePod Mini'), findsOneWidget);
    expect(textWidget('iPhone 15 Pro'), findsNothing);

    await tester.ensureVisible(textWidget('HomePod Mini'));
    await settle(tester);
    await tester.tap(textWidget('HomePod Mini'));
    await settle(tester);
    expect(textWidget('Açıklama'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('detail-scroll')),
      const Offset(0, -350),
    );
    await settle(tester);
    expect(textWidget('3.3 inches'), findsOneWidget);
    expect(textWidget('Sepete Ekle'), findsOneWidget);

    await tester.tap(textWidget('Sepete Ekle'));
    await settle(tester);
    expect(textWidget('Sepetten Çıkar'), findsOneWidget);
    expect(cart.count, 1);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
    await settle(tester);
    expect(textWidget('HomePod Mini'), findsWidgets);
    expect(textWidget('Sepetin boş'), findsNothing);

    await tester.tap(find.textContaining('Sepeti Onayla'));
    await settle(tester);
    expect(textWidget('Siparişi onayla'), findsOneWidget);
    expect(find.textContaining('99 TL'), findsWidgets);

    await tester.tap(textWidget('Devam'));
    await settle(tester);
    expect(textWidget('Ödeme'), findsOneWidget);

    await _fillPayment(tester);
    await _enter(tester, 'Son kullanma tarihi', '3131');
    await tester.tap(find.byKey(const ValueKey('pay-button')));
    await settle(tester);
    expect(
      find.textContaining('kabul edilmez'),
      findsOneWidget,
    );
    expect(textWidget('Ödeme tamamlandı'), findsNothing);

    await _enter(tester, 'Son kullanma tarihi', '1228');
    await _enter(tester, 'Kart şifresi', '000');
    await tester.tap(find.byKey(const ValueKey('pay-button')));
    await settle(tester);
    expect(find.textContaining('deneme kodları'), findsOneWidget);
    expect(textWidget('Ödeme tamamlandı'), findsNothing);

    await _enter(tester, 'Kart şifresi', '258');
    ScaffoldMessenger.of(
      tester.element(find.byType(PaymentScreen)),
    ).clearSnackBars();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('pay-button')));
    await tester.tap(find.byKey(const ValueKey('pay-button')));
    await settle(tester);
    expect(textWidget('Ödeme tamamlandı'), findsOneWidget);

    await tester.tap(textWidget('Tamam'));
    await settle(tester);
    expect(cart.count, 0);
    expect(textWidget('Sepetin boş'), findsOneWidget);
  });

  testWidgets('menu filter and cart remove', (tester) async {
    final cart = CartController();
    addTearDown(cart.dispose);

    final favorites = FavoriteController();
    addTearDown(favorites.dispose);
    await tester.pumpWidget(
      FavoriteScope(
        controller: favorites,
        child: CartScope(
          controller: cart,
          child: MaterialApp(
            home: AppShell(
              loadProducts: () async => const [_phone, _homePod],
            ),
          ),
        ),
      ),
    );
    await settle(tester);

    await tester.tap(find.byKey(const ValueKey('nav-menu')));
    await settle(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Telefon'));
    await settle(tester);

    final screen = find.byKey(const ValueKey('category-screen'));
    expect(
      find.descendant(of: screen, matching: textWidget('iPhone 15 Pro')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: screen, matching: textWidget('HomePod Mini')),
      findsNothing,
    );

    final addButton = find.byTooltip('Sepete ekle');
    await tester.ensureVisible(addButton);
    await settle(tester);
    await tester.tap(addButton);
    await settle(tester);
    expect(cart.count, 1);

    await tester.pageBack();
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('nav-cart')));
    await settle(tester);
    expect(textWidget('iPhone 15 Pro'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('remove-1')));
    await settle(tester);
    expect(cart.count, 0);
    expect(textWidget('Sepetin boş'), findsOneWidget);
  });
}

Future<void> _enter(WidgetTester tester, String label, String value) async {
  final field = _field(label);
  await tester.ensureVisible(field);
  await settle(tester);
  await tester.enterText(field, value);
  await settle(tester);
}

Future<void> _fillPayment(WidgetTester tester) async {
  await _enter(tester, 'Ad soyad', 'Ayşe Yılmaz');
  await _enter(tester, 'Cep telefonu', '05321234567');
  await tester.ensureVisible(find.byKey(const ValueKey('city-dropdown')));
  await settle(tester);
  await tester.tap(find.byKey(const ValueKey('city-dropdown')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('İstanbul').last);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const ValueKey('district-dropdown')));
  await settle(tester);
  await tester.tap(find.byKey(const ValueKey('district-dropdown')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Kadıköy').last);
  await tester.pumpAndSettle();
  await _enter(tester, 'Açık adres', 'Moda Caddesi No 10');
  await _enter(tester, 'Kart üzerindeki isim', 'Ayşe Yılmaz');
  await _enter(tester, 'Kart numarası', '4242424242424242');
  await _enter(tester, 'Son kullanma tarihi', '1228');
  await _enter(tester, 'Kart şifresi', '258');
}
