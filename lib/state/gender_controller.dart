import 'package:flutter/widgets.dart';

/// Cinsiyet tercihi yalnızca bu oturumda durur. null, tüm ürünleri gösterir.
class GenderController extends ValueNotifier<String?> {
  GenderController() : super(null);

  void select(String? gender) {
    value = gender;
  }
}

class GenderScope extends InheritedNotifier<GenderController> {
  const GenderScope({
    required GenderController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static GenderController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GenderScope>();
    assert(scope != null, 'GenderScope bulunamadı');
    return scope!.notifier!;
  }

  static GenderController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GenderScope>()?.notifier;
  }
}
