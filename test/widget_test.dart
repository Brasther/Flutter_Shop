import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_shop/src/providers/cart_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sums quantities and refuses items above the available stock', () async {
    final cart = CartProvider();
    await cart.ready;

    expect(cart.addItem('shoe-1', 20, 'Runner', '', stock: 2), isTrue);
    expect(cart.addItem('shoe-1', 20, 'Runner', '', stock: 2), isTrue);
    expect(cart.addItem('shoe-1', 20, 'Runner', '', stock: 2), isFalse);
    expect(cart.itemCount, 2);
    expect(cart.totalAmount, 40);

    cart.setQuantity('shoe-1', 1);
    expect(cart.totalAmount, 20);
    cart.removeItem('shoe-1');
    expect(cart.items, isEmpty);
    cart.dispose();
  });

  test('restores persisted cart items when a provider is recreated', () async {
    final first = CartProvider();
    await first.ready;
    first.addItem('bag-1', 15.5, 'Everyday Bag', '');
    await Future<void>.delayed(Duration.zero);
    first.dispose();

    final restored = CartProvider();
    await restored.ready;
    expect(restored.items['bag-1']?.title, 'Everyday Bag');
    expect(restored.totalAmount, 15.5);
    restored.dispose();
  });

  test('keeps product options as separate cart lines under shared stock',
      () async {
    final cart = CartProvider();
    await cart.ready;

    expect(
        cart.addItem('shoe', 64.9, 'Urban Runner', '',
            stock: 2, variants: {'Talla': '40'}),
        isTrue);
    expect(
        cart.addItem('shoe', 64.9, 'Urban Runner', '',
            stock: 2, variants: {'Talla': '41'}),
        isTrue);
    expect(cart.canIncrement(cart.items.keys.first), isFalse);
    expect(
        cart.addItem('shoe', 64.9, 'Urban Runner', '',
            stock: 2, variants: {'Talla': '42'}),
        isFalse);
    expect(cart.items.length, 2);
    expect(cart.items.values.map((item) => item.variants['Talla']).toSet(),
        {'40', '41'});
    cart.dispose();
  });
}
