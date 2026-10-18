class Review {
  const Review({
    required this.author,
    required this.stars,
    required this.text,
    required this.date,
  });

  final String author;
  final int stars;
  final String text;
  final String date;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      author: json['author'] as String? ?? '',
      stars: json['stars'] as int? ?? 5,
      text: json['text'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author': author,
      'stars': stars,
      'text': text,
      'date': date,
    };
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.price,
    required this.currency,
    required this.imageUrl,
    required this.specs,
    this.gender,
    this.badge,
    this.listPrice,
    this.flash = false,
    this.rating = 0,
    this.reviewCount = 0,
    this.reviews = const [],
  });

  final int id;
  final String name;
  final String tagline;
  final String description;
  final String price;
  final String currency;
  final String imageUrl;
  final Map<String, String> specs;
  final String? gender;
  final String? badge;
  final String? listPrice;
  final bool flash;
  final double rating;
  final int reviewCount;
  final List<Review> reviews;

  int get discountPercent {
    final was = parsePrice(listPrice ?? '');
    final now = parsePrice(price);
    if (was <= now || was <= 0) {
      return 0;
    }
    return (((was - now) / was) * 100).round();
  }

  /// Menü ve filtre, ürün adından türetilir. JSON şemasına yeni alan eklenmez.
  String get category {
    final value = name.toLowerCase();
    if (value.contains('samsung') || value.contains('galaxy')) {
      return 'Samsung';
    }
    if (value.contains('xiaomi') ||
        value.contains('redmi') ||
        value.contains('poco')) {
      return 'Xiaomi';
    }
    if (value.contains('iphone')) {
      return 'iPhone';
    }
    if (value.contains('ipad')) {
      return 'iPad';
    }
    if (value.contains('watch')) {
      return 'Watch';
    }
    if (value.contains('vision')) {
      return 'Vision';
    }
    if (value.contains('mac')) {
      return 'Mac';
    }
    return 'Audio';
  }

  /// Trendyol vitrinindeki üst kategoriler. Giyim dışındaki her şey teknolojidir.
  String get department {
    final value = _fold(name);
    const clothing = [
      'tisort',
      'sweat',
      'ceket',
      'ayakkabi',
      'elbise',
      'bluz',
      'etek',
      'gomlek',
      'pantolon',
      'canta',
      'kazak',
      'sort',
      'mont',
      'hirka',
    ];
    if (clothing.any(value.contains)) {
      return 'Giyim';
    }
    if (value.contains('watch')) {
      return 'Saat';
    }
    if (value.contains('ipad') ||
        value.contains(' tab') ||
        value.contains('pad ')) {
      return 'Tablet';
    }
    if (value.contains('mac')) {
      return 'Bilgisayar';
    }
    if (value.contains('airpod') ||
        value.contains('homepod') ||
        value.contains('buds')) {
      return 'Ses';
    }
    if (value.contains('vision')) {
      return 'Gözlük';
    }
    return 'Telefon';
  }

  /// Giyimde marka yok. Diğer ürünler Apple, Samsung veya Xiaomi.
  String? get brand {
    if (department == 'Giyim') {
      return null;
    }
    if (category == 'Samsung') {
      return 'Samsung';
    }
    if (category == 'Xiaomi') {
      return 'Xiaomi';
    }
    return 'Apple';
  }

  /// Ağ adresindeki dosya adı, projeye indirilen asset ile eşleşir.
  String get imageAsset {
    final fileName = imageUrl.split('/').last;
    return 'assets/images/$fileName';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawSpecs = json['specs'];
    final specs = <String, String>{};
    if (rawSpecs is Map) {
      rawSpecs.forEach((key, value) {
        specs['$key'] = '$value';
      });
    }

    final reviews = <Review>[];
    final rawReviews = json['reviews'];
    if (rawReviews is List) {
      for (final item in rawReviews) {
        if (item is Map) {
          reviews.add(Review.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return Product(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price'] as String? ?? '',
      currency: json['currency'] as String? ?? 'USD',
      imageUrl: json['image'] as String? ?? '',
      specs: specs,
      gender: json['gender'] as String?,
      badge: json['badge'] as String?,
      listPrice: json['listPrice'] as String?,
      flash: json['flash'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['reviewCount'] as int? ?? reviews.length,
      reviews: reviews,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      'description': description,
      'price': price,
      'currency': currency,
      'image': imageUrl,
      'specs': specs,
      'gender': gender,
      'badge': badge,
      'listPrice': listPrice,
      'flash': flash,
      'rating': rating,
      'reviewCount': reviewCount,
      'reviews': reviews.map((review) => review.toJson()).toList(),
    };
  }
}

bool matchesGender(Product product, String? gender) {
  if (gender == null || gender.isEmpty) {
    return true;
  }
  final value = product.gender;
  if (value == null || value == 'unisex') {
    return true;
  }
  return value == gender;
}

String badgeLabel(String? badge) {
  switch (badge) {
    case 'cokSatan':
      return 'En çok satan';
    case 'cokTercih':
      return 'En çok tercih edilen';
    case 'yeni':
      return 'Yeni';
    default:
      return '';
  }
}

String genderLabel(String? gender) {
  switch (gender) {
    case 'kadin':
      return 'Kadın';
    case 'erkek':
      return 'Erkek';
    case 'unisex':
      return 'Unisex';
    default:
      return 'Tümü';
  }
}

double parsePrice(String price) {
  final cleaned = price.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(cleaned) ?? 0;
}

class StorefrontCategory {
  const StorefrontCategory(this.id, this.label);

  final String id;
  final String label;
}

const storefrontCategories = <StorefrontCategory>[
  StorefrontCategory('teknoloji', 'Teknoloji'),
  StorefrontCategory('giyim', 'Giyim'),
  StorefrontCategory('telefon', 'Telefon'),
  StorefrontCategory('tablet', 'Tablet'),
  StorefrontCategory('bilgisayar', 'Bilgisayar'),
  StorefrontCategory('saat', 'Saat'),
  StorefrontCategory('ses', 'Ses'),
  StorefrontCategory('samsung', 'Samsung'),
  StorefrontCategory('xiaomi', 'Xiaomi'),
];

bool matchesStorefront(Product product, String? categoryId) {
  if (categoryId == null) {
    return true;
  }
  switch (categoryId) {
    case 'teknoloji':
      return product.department != 'Giyim';
    case 'giyim':
      return product.department == 'Giyim';
    case 'telefon':
      return product.department == 'Telefon';
    case 'tablet':
      return product.department == 'Tablet';
    case 'bilgisayar':
      return product.department == 'Bilgisayar';
    case 'saat':
      return product.department == 'Saat';
    case 'ses':
      return product.department == 'Ses';
    case 'samsung':
      return product.category == 'Samsung';
    case 'xiaomi':
      return product.category == 'Xiaomi';
    default:
      return product.category == categoryId || product.department == categoryId;
  }
}

/// Kaynak listedeki iPhone bloğunu dağıtır. Aynı liste her seferinde aynı karışıma düşer.
List<Product> mixCatalog(List<Product> products) {
  final mixed = [...products];
  for (var i = mixed.length - 1; i > 0; i--) {
    final j = (i * 13 + mixed[i].id) % (i + 1);
    final current = mixed[i];
    mixed[i] = mixed[j];
    mixed[j] = current;
  }
  return mixed;
}

String _fold(String value) {
  return value
      .toLowerCase()
      .replaceAll('i̇', 'i')
      .replaceAll('ı', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');
}

const catalogCategories = <String>[
  'iPhone',
  'Mac',
  'iPad',
  'Watch',
  'Vision',
  'Audio',
  'Samsung',
  'Xiaomi',
];

String categoryLabel(String category) {
  switch (category) {
    case 'Watch':
      return 'Saat';
    case 'Audio':
      return 'Ses';
    default:
      return category;
  }
}

String specLabel(String key) {
  switch (key.toLowerCase()) {
    case 'chip':
      return 'İŞLEMCİ';
    case 'material':
    case 'materials':
      return 'MALZEME';
    case 'camera':
      return 'KAMERA';
    case 'size':
    case 'weight':
      return 'BOYUT';
    case 'audio':
      return 'SES';
    case 'colors':
      return 'RENK';
    case 'display':
    case 'screen':
      return 'EKRAN';
    case 'battery':
      return 'PİL';
    case 'id':
      return 'KİLİT';
    case 'ports':
    case 'connectivity':
      return 'BAĞLANTI';
    case 'design':
      return 'TASARIM';
    case 'pencil':
      return 'KALEM';
    case 'case':
      return 'KASA';
    case 'brightness':
      return 'PARLAKLIK';
    case 'gps':
      return 'KONUM';
    case 'feature':
      return 'ÖZELLİK';
    case 'carbon':
      return 'KARBON';
    case 'os':
      return 'SİSTEM';
    case 'control':
      return 'KONTROL';
    case 'driver':
      return 'SÜRÜCÜ';
    case 'cancellation':
      return 'GÜRÜLTÜ';
    case 'home':
      return 'EV';
    case 'sensing':
      return 'ALGILAMA';
    default:
      return key.toUpperCase();
  }
}

String formatTry(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    if (i > 0 && remaining % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }
  return '$buffer TL';
}

String formatUsd(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer('\$');
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    if (i > 0 && remaining % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
