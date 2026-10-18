import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/cart_controller.dart';
import '../theme/app_colors.dart';
import 'payment_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, this.embedded = false});

  static const routeName = '/cart';

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: embedded
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        'Sepetim',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    )
                  : TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: AppColors.text,
                      ),
                      label: const Text(
                        'Sepetim',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: ValueListenableBuilder<List<CartItem>>(
                valueListenable: cart,
                builder: (context, items, _) {
                  if (items.isEmpty) {
                    return const _EmptyCart();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Dismissible(
                        key: ValueKey(item.product.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: AppColors.danger,
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) => cart.remove(item.product.id),
                        child: Card(
                          elevation: 0,
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 4, 8),
                            child: Row(
                              children: [
                                Image.asset(
                                  item.product.imageAsset,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatTry(item.lineTotal),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.price,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            key: ValueKey(
                                              'qty-minus-${item.product.id}',
                                            ),
                                            onPressed: () => cart
                                                .changeQuantity(
                                                  item.product.id,
                                                  -1,
                                                ),
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                            ),
                                          ),
                                          Text('${item.quantity}'),
                                          IconButton(
                                            key: ValueKey(
                                              'qty-plus-${item.product.id}',
                                            ),
                                            onPressed: () => cart
                                                .changeQuantity(
                                                  item.product.id,
                                                  1,
                                                ),
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  key: ValueKey('remove-${item.product.id}'),
                                  tooltip: 'Sil',
                                  onPressed: () => cart.remove(item.product.id),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.danger,
                                  ),
                                ),
                                IconButton(
                                  tooltip: item.selected
                                      ? 'Seçimi kaldır'
                                      : 'Ödemeye dahil et',
                                  onPressed: () =>
                                      cart.toggleSelected(item.product.id),
                                  icon: Icon(
                                    item.selected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: item.selected
                                        ? AppColors.orange
                                        : const Color(0xFFC7C7CC),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seçili ürünler 1-3 iş gününde hazırlanır. Ödeme simülasyondur.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
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
                child: ValueListenableBuilder<List<CartItem>>(
                  valueListenable: cart,
                  builder: (context, items, _) {
                    final total = items.isEmpty
                        ? ''
                        : ' • ${formatTry(cart.selectedTotal)}';
                    return FilledButton(
                      onPressed: () => _checkout(context, cart),
                      child: Text('Sepeti Onayla$total'),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkout(BuildContext context, CartController cart) {
    final selected = cart.selectedItems;
    if (selected.isEmpty) {
      final empty = cart.value.isEmpty;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            empty
                ? 'Sepetin boş. Alışverişe başlamak için ürün ekle.'
                : 'Ödeme için en az bir ürün seç.',
          ),
        ),
      );
      return;
    }

    final total = formatTry(cart.selectedTotal);
    final items = List<CartItem>.from(selected);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Siparişi onayla'),
          content: Text(
            '${cart.selectedCount} ürün seçildi. Toplam $total.\n\n'
            'Teslimat ve kart bilgisi istenecek. Kartından çekim yapılmaz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).clearSnackBars();
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => PaymentScreen(items: items),
                  ),
                );
              },
              child: const Text('Devam'),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shopping_cart_outlined, size: 72, color: Color(0xFFD1D1D6)),
        SizedBox(height: 16),
        Text(
          'Sepetin boş',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 6),
        Text(
          'Alışverişe başlamak için ürün ekle',
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
      ],
    );
  }
}
