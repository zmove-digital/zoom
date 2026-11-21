import 'package:flutter_test/flutter_test.dart';
import 'package:zoom/core/utils/formatters.dart';

void main() {
  test('valores não têm espaço entre o símbolo e o número', () {
    expect(Money.format(1230, '', symbol: r'R$'), r'R$1.230,00');
    expect(Money.format(1230.5, '', symbol: r'US$'), r'US$1.230,50');
    expect(Money.format(-45.9, '', symbol: r'R$'), r'-R$45,90');
    expect(Money.format(1230, ''), '1.230,00');
    expect(Money.compact(1500, r'R$'), r'R$1.5k');
  });
}
