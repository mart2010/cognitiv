import 'package:cartographer/cartographer.dart';
import 'package:test/test.dart';

void main() {
  test('garde la première lettre et la forme du mot', () {
    expect(HintBuilder.firstLetter('Asunción'), 'A_______');
    expect(HintBuilder.firstLetter('Buenos Aires'), 'B_____ _____');
    expect(HintBuilder.firstLetter('Port-au-Prince'), 'P___-__-______');
  });
}
