import 'dart:math' as math;

import '../use_cases/ports/random_source.dart';

/// Implémentation concrète de `RandomSource` (ADR 0005) avec `dart:math`. Une graine
/// optionnelle permet de rejouer une séquence pour le débogage (ADR 0002).
class SystemRandomSource implements RandomSource {
  final math.Random _random;

  SystemRandomSource([int? seed]) : _random = seed == null ? math.Random() : math.Random(seed);

  @override
  int nextInt(int exclusiveMax) => _random.nextInt(exclusiveMax);

  @override
  double nextDouble() => _random.nextDouble();
}
