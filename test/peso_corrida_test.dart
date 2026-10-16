import 'package:flutter_test/flutter_test.dart';
import 'package:giropix/core/utils/peso_corrida.dart';

void main() {
  test('corrida pesada só acima da média, com histórico mínimo', () {
    expect(corridaPesada(80, [10, 10]), isFalse);
    expect(corridaPesada(10, [10, 12, 14]), isFalse);
    expect(corridaPesada(12, [10, 12, 14]), isFalse);
    expect(corridaPesada(13, [10, 12, 14]), isTrue);
    expect(corridaPesada(0, [10, 12, 14]), isFalse);
    expect(corridaPesada(40, [0, 0, 10, 10, 10]), isTrue);
    expect(corridaPesada(40, [0, 0, 10]), isFalse);
  });
}
