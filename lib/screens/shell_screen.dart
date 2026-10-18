import 'package:flutter/material.dart';

import '../data/product_repository.dart';
import '../models/product.dart';
import '../state/cart_controller.dart';
import '../theme/app_colors.dart';
import '../state/favorite_controller.dart';
import 'cart_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'menu_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.loadProducts});

  final Future<List<Product>> Function()? loadProducts;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _repository = const ProductRepository();

  late final Future<List<Product>> _productsFuture;
  int _index = 0;
  String? _category;

  @override
  void initState() {
    super.initState();
    _productsFuture = widget.loadProducts?.call() ?? _repository.loadProducts();
  }

  void _selectCategory(String? category) {
    setState(() {
      _category = category;
      _index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            loadProducts: () => _productsFuture,
            category: _category,
            onCategoryChanged: _selectCategory,
            onOpenCart: () => setState(() => _index = 3),
          ),
          MenuScreen(productsFuture: _productsFuture),
          const FavoritesScreen(),
          const CartScreen(embedded: true),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder<List<CartItem>>(
        valueListenable: cart,
        builder: (context, items, _) {
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (index) => setState(() => _index = index),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined, key: ValueKey('nav-discover')),
                selectedIcon: Icon(Icons.home),
                label: 'Ana Sayfa',
              ),
              const NavigationDestination(
                icon: Icon(
                  Icons.grid_view_outlined,
                  key: ValueKey('nav-menu'),
                ),
                selectedIcon: Icon(Icons.grid_view, key: ValueKey('nav-menu')),
                label: 'Kategoriler',
              ),
              NavigationDestination(
                icon: _FavoriteIcon(
                  key: const ValueKey('nav-favorites'),
                  selected: false,
                ),
                selectedIcon: const _FavoriteIcon(selected: true),
                label: 'Favoriler',
              ),
              NavigationDestination(
                icon: _CartIcon(
                  key: const ValueKey('nav-cart'),
                  count: cart.count,
                  selected: false,
                ),
                selectedIcon: _CartIcon(count: cart.count, selected: true),
                label: 'Sepetim',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FavoriteIcon extends StatelessWidget {
  const _FavoriteIcon({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final favorites = FavoriteScope.of(context);
    return ValueListenableBuilder(
      valueListenable: favorites,
      builder: (context, items, _) {
        return Badge(
          isLabelVisible: items.isNotEmpty,
          label: Text('${items.length}'),
          backgroundColor: AppColors.orange,
          child: Icon(selected ? Icons.favorite : Icons.favorite_border),
        );
      },
    );
  }
}

class _CartIcon extends StatelessWidget {
  const _CartIcon({super.key, required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      backgroundColor: AppColors.orange,
      child: Icon(selected ? Icons.shopping_bag : Icons.shopping_bag_outlined),
    );
  }
}
