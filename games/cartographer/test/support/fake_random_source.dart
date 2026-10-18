import 'package:cartographer/cartographer.dart';

/// Doublure déterministe de `RandomSource` (ADR 0005) : rejoue une séquence fixe plutôt que de
/// produire un vrai hasard. Préférée à un mock.
class FakeRandomSource implements RandomSource {
  final List<int> ints;
  final List<double> doubles;
  int _intIndex = 0;
  int _doubleIndex = 0;

  FakeRandomSource({this.ints = const [0], this.doubles = const [0.0]});

  @override
  int nextInt(int exclusiveMax) => ints[_intIndex++ % ints.length] % exclusiveMax;

  @override
  double nextDouble() => doubles[_doubleIndex++ % doubles.length];
}
