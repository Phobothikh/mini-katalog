import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/gender_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/product_tile.dart';

enum _Sort { mixed, priceAsc, priceDesc, nameAsc, nameDesc }

enum _PriceBand { any, under500, mid, over1000 }

const _brands = <String>['Apple', 'Samsung', 'Xiaomi'];

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({
    super.key,
    required this.title,
    required this.categoryId,
    required this.productsFuture,
  });

  final String title;
  final String categoryId;
  final Future<List<Product>> productsFuture;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  _Sort _sort = _Sort.mixed;
  _PriceBand _band = _PriceBand.any;
  String? _brand;

  bool get _showBrands {
    const tech = {
      'teknoloji',
      'telefon',
      'tablet',
      'bilgisayar',
      'saat',
      'ses',
    };
    return tech.contains(widget.categoryId);
  }

  List<Product> _apply(List<Product> source, String? gender) {
    final filtered = source.where((product) {
      if (!matchesStorefront(product, widget.categoryId)) {
        return false;
      }
      if (!matchesGender(product, gender)) {
        return false;
      }
      if (_brand != null && product.brand != _brand) {
        return false;
      }
      final price = parsePrice(product.price);
      return switch (_band) {
        _PriceBand.any => true,
        _PriceBand.under500 => price < 15000,
        _PriceBand.mid => price >= 15000 && price <= 50000,
        _PriceBand.over1000 => price > 50000,
      };
    }).toList();

    switch (_sort) {
      case _Sort.priceAsc:
        filtered.sort(
          (a, b) => parsePrice(a.price).compareTo(parsePrice(b.price)),
        );
      case _Sort.priceDesc:
        filtered.sort(
          (a, b) => parsePrice(b.price).compareTo(parsePrice(a.price)),
        );
      case _Sort.nameAsc:
        filtered.sort((a, b) => a.name.compareTo(b.name));
      case _Sort.nameDesc:
        filtered.sort((a, b) => b.name.compareTo(a.name));
      case _Sort.mixed:
        return mixCatalog(filtered);
    }
    return filtered;
  }

  Future<void> _openSort() async {
    final picked = await showModalBottomSheet<_Sort>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final sort in _Sort.values)
                ListTile(
                  title: Text(_sortLabel(sort)),
                  trailing: _sort == sort
                      ? const Icon(Icons.check, color: AppColors.brand)
                      : null,
                  onTap: () => Navigator.pop(context, sort),
                ),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => _sort = picked);
    }
  }

  Future<void> _openFilter() async {
    var brand = _brand;
    var band = _band;
    final genderController = GenderScope.maybeOf(context);
    var gender = genderController?.value;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showBrands) ...[
                      const Text(
                        'Marka',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Tümü'),
                            selected: brand == null,
                            onSelected: (_) => setSheet(() => brand = null),
                          ),
                          for (final item in _brands)
                            ChoiceChip(
                              label: Text(item),
                              selected: brand == item,
                              onSelected: (_) => setSheet(() => brand = item),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'Cinsiyet',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final item in const [null, 'kadin', 'erkek'])
                          ChoiceChip(
                            label: Text(genderLabel(item)),
                            selected: gender == item,
                            onSelected: (_) => setSheet(() => gender = item),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Fiyat',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in _PriceBand.values)
                          ChoiceChip(
                            label: Text(_bandLabel(item)),
                            selected: band == item,
                            onSelected: (_) => setSheet(() => band = item),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Uygula'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (applied == true) {
      genderController?.select(gender);
      setState(() {
        _brand = brand;
        _band = band;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('category-screen'),
      backgroundColor: AppColors.page,
      appBar: AppBar(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<Product>>(
        future: widget.productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Ürünler yüklenemedi.'));
          }
          final products = _apply(
            snapshot.data ?? const [],
            GenderScope.maybeOf(context)?.value,
          );
          return Column(
            children: [
              Material(
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        key: const ValueKey('category-sort'),
                        onPressed: _openSort,
                        icon: const Icon(Icons.swap_vert, color: AppColors.text),
                        label: Text(
                          _sortLabel(_sort),
                          style: const TextStyle(color: AppColors.text),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 22, color: AppColors.line),
                    Expanded(
                      child: TextButton.icon(
                        key: const ValueKey('category-filter'),
                        onPressed: _openFilter,
                        icon: const Icon(
                          Icons.filter_alt_outlined,
                          color: AppColors.text,
                        ),
                        label: const Text(
                          'Filtrele',
                          style: TextStyle(color: AppColors.text),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_showBrands)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _BrandChip(
                        label: 'Tüm markalar',
                        selected: _brand == null,
                        onTap: () => setState(() => _brand = null),
                      ),
                      for (final brand in _brands)
                        _BrandChip(
                          label: brand,
                          selected: _brand == brand,
                          onTap: () => setState(() => _brand = brand),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: products.isEmpty
                    ? const Center(child: Text('Bu filtrede ürün yok.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.58,
                            ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
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
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.text,
          fontWeight: FontWeight.w700,
        ),
        selectedColor: AppColors.brand,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? AppColors.brand : AppColors.line),
      ),
    );
  }
}

String _sortLabel(_Sort sort) {
  switch (sort) {
    case _Sort.mixed:
      return 'Karışık';
    case _Sort.priceAsc:
      return 'En düşük fiyat';
    case _Sort.priceDesc:
      return 'En yüksek fiyat';
    case _Sort.nameAsc:
      return 'Ada göre A-Z';
    case _Sort.nameDesc:
      return 'Ada göre Z-A';
  }
}

String _bandLabel(_PriceBand band) {
  switch (band) {
    case _PriceBand.any:
      return 'Tümü';
    case _PriceBand.under500:
      return '15.000 TL altı';
    case _PriceBand.mid:
      return '15.000-50.000 TL';
    case _PriceBand.over1000:
      return '50.000 TL üzeri';
  }
}
