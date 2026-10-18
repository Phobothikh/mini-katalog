import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/product.dart';

/// Ürün listesini ağ isteği yerine asset içindeki JSON simülasyonundan okur.
class ProductRepository {
  const ProductRepository();

  Future<List<Product>> loadProducts() async {
    final raw = await rootBundle.loadString('assets/data/products.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final items = decoded['data'] as List<dynamic>;
    return items
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
