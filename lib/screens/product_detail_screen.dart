import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/cart_controller.dart';
import '../state/favorite_controller.dart';
import '../theme/app_colors.dart';

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  static const routeName = '/product';

  final Product product;

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: AppColors.text,
                  ),
                  label: const Text(
                    'Geri',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                _FavoriteButton(product: product),
              ],
            ),
            Expanded(
              child: ListView(
                key: const ValueKey('detail-scroll'),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Center(
                    child: Image.asset(
                      product.imageAsset,
                      height: 260,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.tagline,
                    style: const TextStyle(fontSize: 15, color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  if (badgeLabel(product.badge).isNotEmpty) ...[
                    _Badge(label: badgeLabel(product.badge)),
                    const SizedBox(height: 8),
                  ],
                  if (product.discountPercent > 0)
                    Text(
                      formatTry(parsePrice(product.listPrice!)),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.muted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    formatTry(parsePrice(product.price)),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.price,
                    ),
                  ),
                  if (product.discountPercent > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Flaş indirim %${product.discountPercent}',
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  const Text(
                    'Açıklama',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Özellikler',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final entry in product.specs.entries)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.orangeSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  specLabel(entry.key),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 0.4,
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  entry.value,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (product.reviews.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Text(
                      'Yorumlar (${product.reviewCount})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bu yorumlar eğitim için yazılmış örnek metinlerdir.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                    for (final review in product.reviews)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.page,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${review.author} · ${'★' * review.stars}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(review.text),
                              const SizedBox(height: 4),
                              Text(
                                review.date,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ValueListenableBuilder<List<CartItem>>(
                valueListenable: cart,
                builder: (context, items, _) {
                  final inCart = cart.contains(product.id);
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: inCart
                            ? AppColors.danger
                            : AppColors.orange,
                      ),
                      onPressed: () {
                        final messenger = ScaffoldMessenger.of(context);
                        if (inCart) {
                          cart.remove(product.id);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                '${product.name} sepetten çıkarıldı.',
                              ),
                            ),
                          );
                          return;
                        }
                        cart.add(product);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('${product.name} sepete eklendi.'),
                          ),
                        );
                      },
                      child: Text(inCart ? 'Sepetten Çıkar' : 'Sepete Ekle'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final favorites = FavoriteScope.maybeOf(context);
    if (favorites == null) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<List<Product>>(
      valueListenable: favorites,
      builder: (context, items, _) {
        final saved = favorites.contains(product.id);
        return IconButton(
          tooltip: saved ? 'Favorilerden çıkar' : 'Favorilere ekle',
          onPressed: () => favorites.toggle(product),
          icon: Icon(
            saved ? Icons.favorite : Icons.favorite_border,
            color: saved ? AppColors.danger : AppColors.text,
          ),
        );
      },
    );
  }
}
