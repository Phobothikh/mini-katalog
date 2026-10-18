import 'package:flutter/widgets.dart';

import '../models/product.dart';

/// Favoriler, sepet gibi yalnızca bu oturumda tutulur.
class FavoriteController extends ValueNotifier<List<Product>> {
  FavoriteController() : super(const []);

  bool contains(int productId) {
    return value.any((product) => product.id == productId);
  }

  void toggle(Product product) {
    if (contains(product.id)) {
      value = value.where((item) => item.id != product.id).toList();
      return;
    }
    value = [...value, product];
  }
}

class FavoriteScope extends InheritedNotifier<FavoriteController> {
  const FavoriteScope({
    required FavoriteController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static FavoriteController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FavoriteScope>();
    assert(scope != null, 'FavoriteScope bulunamadı');
    return scope!.notifier!;
  }

  static FavoriteController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FavoriteScope>()
        ?.notifier;
  }
}
