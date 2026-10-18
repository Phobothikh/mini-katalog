import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/cart_controller.dart';
import '../state/favorite_controller.dart';
import '../state/gender_controller.dart';
import '../theme/app_colors.dart';

const raffleSpendTry = 5000.0;

class RaffleScreen extends StatefulWidget {
  const RaffleScreen({super.key});

  @override
  State<RaffleScreen> createState() => _RaffleScreenState();
}

class _RaffleScreenState extends State<RaffleScreen> {
  bool _joined = false;

  @override
  Widget build(BuildContext context) {
    final favorites = FavoriteScope.of(context);
    final cart = CartScope.of(context);
    final gender = GenderScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        title: const Text('Şartlı çekiliş'),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([favorites, cart, gender]),
        builder: (context, _) {
          final hasGender = gender.value == 'kadin' || gender.value == 'erkek';
          final hasFavorite = favorites.value.isNotEmpty;
          final hasCart = cart.count > 0;
          final spent = cart.selectedTotal;
          final hasSpend = spent >= raffleSpendTry;
          final ready = hasGender && hasFavorite && hasCart && hasSpend;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Haftanın eğitim çekilişi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ödül kutusu bir katalog ürünü gibi görünür. Kazanan açıklanmaz, kargo çıkmaz ve ödeme alınmaz. Bu ekran yalnızca şartlı katılımı göstermek içindir.',
                      style: TextStyle(height: 1.4, color: AppColors.text),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Katılım şartları',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _Condition(
                done: hasGender,
                title: 'Cinsiyet tercihi seç',
                detail: 'Ana sayfada Kadın veya Erkek. Tümü katılım için yetmez.',
              ),
              _Condition(
                done: hasFavorite,
                title: 'En az bir ürünü favorile',
                detail: 'Kalp simgesiyle bir ürünü favorilere ekle.',
              ),
              _Condition(
                done: hasCart,
                title: 'Sepete en az bir ürün ekle',
                detail: 'Sepet dolu olmalı. Ödeme yapmak zorunlu değil.',
              ),
              _Condition(
                done: hasSpend,
                title: 'Sepet tutarı en az 5.000 TL',
                detail:
                    'Şu an ${formatTry(spent)}. Eşik 5.000 TL. Ödeme almak zorunda değilsin.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: !ready || _joined
                      ? null
                      : () {
                          setState(() => _joined = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Katıldın. Bu bir simülasyondur, gerçek ödül yoktur.',
                              ),
                            ),
                          );
                        },
                  child: Text(_joined ? 'Katıldın' : 'Çekilişe katıl'),
                ),
              ),
              if (!ready) ...[
                const SizedBox(height: 8),
                const Text(
                  'Dört şart da tamamlanınca buton açılır.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Condition extends StatelessWidget {
  const _Condition({
    required this.done,
    required this.title,
    required this.detail,
  });

  final bool done;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: done ? AppColors.orange : AppColors.line),
      ),
      child: ListTile(
        leading: Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? AppColors.orange : AppColors.muted,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(detail),
      ),
    );
  }
}
