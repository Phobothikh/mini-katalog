import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/favorite_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/product_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = FavoriteScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Favoriler',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<List<Product>>(
                valueListenable: favorites,
                builder: (context, items, _) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 72,
                            color: Color(0xFFD1D1D6),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Henüz favorin yok',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Kalbe bastığın ürünler burada durur',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.62,
                        ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final product = items[index];
                      return ProductTile(
                        product: product,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/product',
                            arguments: product,
                          );
                        },
                      );
                    },
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
