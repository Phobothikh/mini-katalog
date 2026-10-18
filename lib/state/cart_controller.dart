import 'package:flutter/widgets.dart';

import '../models/product.dart';

class CartItem {
  CartItem({required this.product, this.selected = true, this.quantity = 1});

  final Product product;
  final bool selected;
  final int quantity;

  double get lineTotal => parsePrice(product.price) * quantity;
}

/// Sepet, ek paket kullanmadan ValueNotifier ile tutulur.
class CartController extends ValueNotifier<List<CartItem>> {
  CartController() : super(const []);

  int get count => value.fold<int>(0, (sum, item) => sum + item.quantity);

  bool contains(int productId) {
    return value.any((item) => item.product.id == productId);
  }

  void add(Product product) {
    if (contains(product.id)) {
      changeQuantity(product.id, 1);
      return;
    }
    value = [...value, CartItem(product: product)];
  }

  void changeQuantity(int productId, int delta) {
    final next = <CartItem>[];
    for (final item in value) {
      if (item.product.id != productId) {
        next.add(item);
        continue;
      }
      final quantity = item.quantity + delta;
      if (quantity > 0) {
        next.add(
          CartItem(
            product: item.product,
            selected: item.selected,
            quantity: quantity,
          ),
        );
      }
    }
    value = next;
  }

  void remove(int productId) {
    value = value.where((item) => item.product.id != productId).toList();
  }

  void removePaid(Iterable<int> productIds) {
    final ids = productIds.toSet();
    value = value.where((item) => !ids.contains(item.product.id)).toList();
  }

  void toggleSelected(int productId) {
    value = [
      for (final item in value)
        if (item.product.id == productId)
          CartItem(
            product: item.product,
            selected: !item.selected,
            quantity: item.quantity,
          )
        else
          item,
    ];
  }

  List<CartItem> get selectedItems {
    return value.where((item) => item.selected).toList();
  }

  int get selectedCount {
    return selectedItems.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  double get selectedTotal {
    return selectedItems.fold<double>(0, (sum, item) => sum + item.lineTotal);
  }
}

class CartScope extends InheritedNotifier<CartController> {
  const CartScope({
    required CartController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static CartController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CartScope>();
    assert(scope != null, 'CartScope bulunamadı');
    return scope!.notifier!;
  }
}
