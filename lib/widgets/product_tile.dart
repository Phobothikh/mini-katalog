import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/cart_controller.dart';
import '../state/favorite_controller.dart';
import '../theme/app_colors.dart';

class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 220;
        if (constraints.maxHeight < 96) {
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(product.imageAsset, fit: BoxFit.contain),
            ),
          );
        }
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(compact ? 8 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _visual()),
                  const SizedBox(height: 6),
                  if (!compact && product.brand != null)
                    Text(
                      product.brand!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand,
                        letterSpacing: 0.4,
                      ),
                    ),
                  Text(
                    product.name,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!compact && product.discountPercent > 0)
                    Text(
                      formatTry(parsePrice(product.listPrice!)),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    formatTry(parsePrice(product.price)),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.price,
                    ),
                  ),
                  if (!compact && product.reviewCount > 0)
                    Text(
                      '${product.rating.toStringAsFixed(1).replaceAll('.', ',')} · ${product.reviewCount} yorum',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _visual() {
    return Stack(
      children: [
        Center(
          child: Image.asset(
            product.imageAsset,
            fit: BoxFit.contain,
          ),
        ),
        if (badgeLabel(product.badge).isNotEmpty)
          Positioned(
            left: 0,
            top: 0,
            right: 28,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _Badge(label: badgeLabel(product.badge)),
            ),
          ),
        if (product.discountPercent > 0)
          Positioned(
            right: 0,
            top: 0,
            child: _Badge(label: '%${product.discountPercent}'),
          ),
        Positioned(
          left: 0,
          bottom: 0,
          child: _FavoriteToggle(product: product),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: _CartToggle(product: product),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FavoriteToggle extends StatelessWidget {
  const _FavoriteToggle({required this.product});

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
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: saved ? AppColors.danger : AppColors.muted,
          ),
          icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
        );
      },
    );
  }
}

class _CartToggle extends StatelessWidget {
  const _CartToggle({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);
    return ValueListenableBuilder<List<CartItem>>(
      valueListenable: cart,
      builder: (context, items, _) {
        final inCart = cart.contains(product.id);
        return IconButton(
          tooltip: inCart ? 'Sepetten çıkar' : 'Sepete ekle',
          onPressed: () {
            if (inCart) {
              cart.remove(product.id);
              return;
            }
            cart.add(product);
          },
          style: IconButton.styleFrom(
            backgroundColor: inCart ? AppColors.orangeSoft : Colors.white,
            foregroundColor: inCart ? AppColors.danger : AppColors.orange,
          ),
          icon: Icon(
            inCart
                ? Icons.remove_shopping_cart_outlined
                : Icons.add_shopping_cart,
          ),
        );
      },
    );
  }
}
