import 'package:workshop/workshop.dart';

/// Doublure déterministe de `RandomSource` (ADR 0005) : rejoue une séquence fixe
/// d'entiers et de flottants plutôt que de produire un vrai hasard, pour des tests
/// reproductibles. Préférée à un mock (CLAUDE.md : « Default to Fakes over mocks »).
class FakeRandomSource implements RandomSource {
  final List<int> ints;
  final List<double> doubles;
  int _intIndex = 0;
  int _doubleIndex = 0;

  FakeRandomSource({this.ints = const [0], this.doubles = const [0.0]});

  @override
  int nextInt(int exclusiveMax) {
    final value = ints[_intIndex % ints.length];
    _intIndex++;
    return value % exclusiveMax;
  }

  @override
  double nextDouble() {
    final value = doubles[_doubleIndex % doubles.length];
    _doubleIndex++;
    return value;
  }
}
