import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/app_colors.dart';
import 'category_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key, required this.productsFuture});

  final Future<List<Product>> productsFuture;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'Kategoriler',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Bir kategori seç, ürünlerine geç.',
                style: TextStyle(fontSize: 15, color: AppColors.muted),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Ürünler yüklenemedi.'));
                  }
                  final products = snapshot.data ?? const <Product>[];
                  return ListView(
                    children: [
                      for (final category in storefrontCategories)
                        _CategoryTile(
                          label: category.label,
                          count: products
                              .where(
                                (product) => matchesStorefront(
                                  product,
                                  category.id,
                                ),
                              )
                              .length,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => CategoryScreen(
                                  title: category.label,
                                  categoryId: category.id,
                                  productsFuture: productsFuture,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.chevron_right, color: AppColors.orange),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        subtitle: Text(
          '$count ürün',
          style: const TextStyle(color: AppColors.muted),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFC7C7CC)),
      ),
    );
  }
}
