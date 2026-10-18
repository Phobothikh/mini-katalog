# Mini Katalog Uygulaması

Flutter ile geliştirilmiş temel bir ürün kataloğu. Ana sayfada ürünler ızgara halinde listelenir, ürün detayına geçilir ve sepet simülasyonu yapılır.

Uygulama eğitim amaçlıdır. Ürün adları ve görseller ilgili markaların mülkiyetindedir; bu proje o markalarla bağlantılı değildir. Veriler [wantapi.com/products.php](https://wantapi.com/products.php) adresinden alınmış bir JSON simülasyonudur. Ek paket kullanılmaz; yalnızca Flutter SDK ve `material.dart` kullanılır.

## Kullanılan Flutter sürümü

- Flutter 3.47.7
- Dart 3.13.5

## Çalıştırma adımları

1. [Flutter SDK](https://docs.flutter.dev/get-started/install) kurulu olmalı ve `flutter` komutu PATH içinde olmalıdır.
2. Proje klasöründe bağımlılıkları alın:

```bash
flutter pub get
```

3. Uygulamayı çalıştırın.

Chrome üzerinde:

```bash
flutter run -d chrome
```

Android emülatör veya bağlı bir cihazda:

```bash
flutter run
```

Android emülatör için Android Studio ve bir sanal cihaz gerekir. iOS derlemesi yalnızca macOS üzerinde yapılabilir.

## Proje yapısı

- `lib/main.dart` — uygulama teması ve named route tanımları
- `lib/models/product.dart` — ürün modeli, `fromJson` / `toJson`
- `lib/data/product_repository.dart` — `assets/data/products.json` okuma
- `lib/screens/home_screen.dart` — arama, banner ve `GridView`
- `lib/screens/product_detail_screen.dart` — detay ve sepete ekleme
- `lib/screens/cart_screen.dart` — `ListView.builder` ile sepet
- `lib/state/cart_controller.dart` — sepet state simülasyonu
- `assets/images/` — banner ve ürün görselleri
