import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/product_repository.dart';
import '../models/product.dart';
import '../state/cart_controller.dart';
import '../theme/app_colors.dart';
import '../state/gender_controller.dart';
import '../widgets/product_tile.dart';
import 'cart_screen.dart';
import 'category_screen.dart';
import 'raffle_screen.dart';

enum ProductSort { recommended, priceAsc, priceDesc, nameAsc, nameDesc }

enum PriceBand { any, under500, mid, over1000 }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.loadProducts,
    this.category,
    this.onCategoryChanged,
    this.onOpenCart,
  });

  final Future<List<Product>> Function()? loadProducts;
  final String? category;
  final ValueChanged<String?>? onCategoryChanged;
  final VoidCallback? onOpenCart;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _repository = const ProductRepository();
  final _searchController = TextEditingController();

  late final Future<List<Product>> _productsFuture;
  late final AnimationController _neonPulse;
  String _query = '';
  String? _ownCategory;
  ProductSort _sort = ProductSort.recommended;
  PriceBand _priceBand = PriceBand.any;
  bool _flashOnly = false;

  @override
  void initState() {
    super.initState();
    _neonPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _productsFuture = widget.loadProducts?.call() ?? _repository.loadProducts();
  }

  @override
  void dispose() {
    _neonPulse.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String? get _category {
    if (widget.onCategoryChanged != null) {
      return widget.category;
    }
    return _ownCategory;
  }

  void _setCategory(String? category) {
    if (widget.onCategoryChanged != null) {
      widget.onCategoryChanged!(category);
      return;
    }
    setState(() => _ownCategory = category);
  }

  List<Product> _visible(List<Product> products, String? gender) {
    final query = _query.trim().toLowerCase();
    final category = _category;
    final filtered = products.where((product) {
      if (!matchesStorefront(product, category)) {
        return false;
      }
      if (!matchesGender(product, gender)) {
        return false;
      }
      final price = parsePrice(product.price);
      final matchesPrice = switch (_priceBand) {
        PriceBand.any => true,
        PriceBand.under500 => price < 15000,
        PriceBand.mid => price >= 15000 && price <= 50000,
        PriceBand.over1000 => price > 50000,
      };
      if (!matchesPrice) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return product.name.toLowerCase().contains(query) ||
          product.tagline.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          categoryLabel(product.category).toLowerCase().contains(query);
    }).toList();

    switch (_sort) {
      case ProductSort.priceAsc:
        filtered.sort(
          (a, b) => parsePrice(a.price).compareTo(parsePrice(b.price)),
        );
      case ProductSort.priceDesc:
        filtered.sort(
          (a, b) => parsePrice(b.price).compareTo(parsePrice(a.price)),
        );
      case ProductSort.nameAsc:
        filtered.sort((a, b) => a.name.compareTo(b.name));
      case ProductSort.nameDesc:
        filtered.sort((a, b) => b.name.compareTo(a.name));
      case ProductSort.recommended:
        return mixCatalog(filtered);
    }
    return filtered;
  }

  Future<void> _openSort() async {
    final picked = await showModalBottomSheet<ProductSort>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Sırala',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              for (final sort in ProductSort.values)
                ListTile(
                  title: Text(_sortLabel(sort)),
                  trailing: _sort == sort
                      ? const Icon(Icons.check, color: AppColors.orange)
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
    var category = _category;
    var band = _priceBand;
    final genderController = GenderScope.maybeOf(context);
    var gender = genderController?.value;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtrele',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Kategori',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Tümü'),
                          selected: category == null,
                          onSelected: (_) =>
                              setSheetState(() => category = null),
                        ),
                        for (final item in storefrontCategories)
                          ChoiceChip(
                            label: Text(item.label),
                            selected: category == item.id,
                            onSelected: (_) =>
                                setSheetState(() => category = item.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Cinsiyet',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final item in const [null, 'kadin', 'erkek'])
                          ChoiceChip(
                            label: Text(genderLabel(item)),
                            selected: gender == item,
                            onSelected: (_) =>
                                setSheetState(() => gender = item),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Fiyat',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in PriceBand.values)
                          ChoiceChip(
                            label: Text(_priceLabel(item)),
                            selected: band == item,
                            onSelected: (_) => setSheetState(() => band = item),
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
      _setCategory(category);
      genderController?.select(gender);
      setState(() => _priceBand = band);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: Column(
        children: [
          Container(
            color: AppColors.orange,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Mini Katalog',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        ValueListenableBuilder<List<CartItem>>(
                          valueListenable: CartScope.of(context),
                          builder: (context, items, _) {
                            return IconButton(
                              onPressed: () {
                                final openCart = widget.onOpenCart;
                                if (openCart != null) {
                                  openCart();
                                  return;
                                }
                                Navigator.pushNamed(
                                  context,
                                  CartScreen.routeName,
                                );
                              },
                              icon: Badge(
                                isLabelVisible: items.isNotEmpty,
                                label: Text('${CartScope.of(context).count}'),
                                backgroundColor: Colors.white,
                                textColor: AppColors.orange,
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Ürün veya kategori ara',
                        hintStyle: const TextStyle(color: AppColors.muted),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.orange,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Material(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    key: const ValueKey('sort-button'),
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
                    key: const ValueKey('filter-button'),
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
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: _AutoStrip(
              itemCount: storefrontCategories.length,
              itemExtent: 96,
              speed: 56,
              itemBuilder: (context, index) {
                final item = storefrontCategories[
                    index % storefrontCategories.length];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 10, 6),
                  child: _StorefrontButton(
                    label: item.label,
                    image: 'assets/images/cat_${item.id}.png',
                    pulse: _neonPulse,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => CategoryScreen(
                            title: item.label,
                            categoryId: item.id,
                            productsFuture: _productsFuture,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Ürünler yüklenemedi.'));
                }

                final genderController = GenderScope.maybeOf(context);
                final products = _visible(
                  snapshot.data ?? const [],
                  genderController?.value,
                );
                final flash = products
                    .where(
                      (product) =>
                          product.flash && product.discountPercent > 0,
                    )
                    .toList();
                final shown = _flashOnly ? flash : products;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (genderController != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                        child: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Cinsiyet',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            for (final item in const [null, 'kadin', 'erkek'])
                              ChoiceChip(
                                label: Text(genderLabel(item)),
                                selected: genderController.value == item,
                                onSelected: (_) =>
                                    genderController.select(item),
                              ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const RaffleScreen(),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.card_giftcard,
                                  color: AppColors.orange,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Şartlı çekiliş · en az 5.000 TL',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: AppColors.muted),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Tüm ürünler'),
                            selected: !_flashOnly,
                            onSelected: (_) =>
                                setState(() => _flashOnly = false),
                          ),
                          ChoiceChip(
                            label: Text(
                              flash.isEmpty
                                  ? 'Flaş indirimler'
                                  : 'Flaş indirimler (${flash.length})',
                            ),
                            selected: _flashOnly,
                            onSelected: flash.isEmpty
                                ? null
                                : (_) => setState(() => _flashOnly = true),
                          ),
                        ],
                      ),
                    ),
                    if (shown.isEmpty)
                      const Expanded(
                        child: Center(child: Text('Bu filtrede ürün yok.')),
                      )
                    else
                      Expanded(child: _filmStrip(context, shown)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget _stripTile(BuildContext context, Product product) {
  return SizedBox(
    width: 180,
    child: ProductTile(
      product: product,
      onTap: () {
        Navigator.pushNamed(context, '/product', arguments: product);
      },
    ),
  );
}

String _sortLabel(ProductSort sort) {
  switch (sort) {
    case ProductSort.recommended:
      return 'Önerilen';
    case ProductSort.priceAsc:
      return 'En düşük fiyat';
    case ProductSort.priceDesc:
      return 'En yüksek fiyat';
    case ProductSort.nameAsc:
      return 'Ada göre A-Z';
    case ProductSort.nameDesc:
      return 'Ada göre Z-A';
  }
}

String _priceLabel(PriceBand band) {
  switch (band) {
    case PriceBand.any:
      return 'Tümü';
    case PriceBand.under500:
      return '15.000 TL altı';
    case PriceBand.mid:
      return '15.000-50.000 TL';
    case PriceBand.over1000:
      return '50.000 TL üzeri';
  }
}

class _StorefrontButton extends StatelessWidget {
  const _StorefrontButton({
    required this.label,
    required this.image,
    required this.pulse,
    required this.onTap,
  });

  final String label;
  final String image;
  final Animation<double> pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final glow = Curves.easeInOut.transform(pulse.value);
        return InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 86,
            child: Column(
              children: [
                Container(
                  width: 74,
                  height: 74,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(AppColors.neonEdge, AppColors.neon, glow)!,
                        Color.lerp(AppColors.neon, Colors.white, glow * 0.45)!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neon.withValues(alpha: 0.15 + glow * 0.85),
                        blurRadius: 6 + glow * 18,
                        spreadRadius: glow * 3,
                      ),
                      BoxShadow(
                        color: AppColors.neonEdge.withValues(
                          alpha: 0.1 + glow * 0.6,
                        ),
                        blurRadius: 4 + glow * 12,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(image, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _filmStrip(BuildContext context, List<Product> products) {
  return _AutoStrip(
    itemCount: products.length,
    itemExtent: 196,
    speed: 40,
    itemBuilder: (context, index) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 0, 12),
        child: _stripTile(context, products[index % products.length]),
      );
    },
  );
}

class _AutoStrip extends StatefulWidget {
  const _AutoStrip({
    required this.itemCount,
    required this.itemExtent,
    required this.speed,
    required this.itemBuilder,
  });

  final int itemCount;
  final double itemExtent;
  final double speed;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  State<_AutoStrip> createState() => _AutoStripState();
}

class _AutoStripState extends State<_AutoStrip>
    with SingleTickerProviderStateMixin {
  final _controller = ScrollController();
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  var _held = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(_AutoStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount && _controller.hasClients) {
      _controller.jumpTo(0);
    }
  }

  void _onTick(Duration elapsed) {
    final previous = _last;
    _last = elapsed;
    if (previous == Duration.zero || _held || !_controller.hasClients) {
      return;
    }
    final seconds = (elapsed - previous).inMicroseconds / 1000000;
    if (seconds <= 0 || seconds > 0.05) {
      return;
    }
    final loop = widget.itemCount * widget.itemExtent;
    final max = _controller.position.maxScrollExtent;
    if (loop <= 0 || max <= 0) {
      return;
    }
    var next = _controller.offset + seconds * widget.speed;
    if (next >= loop) {
      next -= loop;
    }
    _controller.jumpTo(next.clamp(0, max));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) {
      return const SizedBox.shrink();
    }
    return Listener(
      onPointerDown: (_) => _held = true,
      onPointerUp: (_) => _held = false,
      onPointerCancel: (_) => _held = false,
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemExtent: widget.itemExtent,
        itemCount: widget.itemCount * 2,
        itemBuilder: widget.itemBuilder,
      ),
    );
  }
}
