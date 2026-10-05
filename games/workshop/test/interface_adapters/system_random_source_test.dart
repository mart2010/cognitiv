import 'package:test/test.dart';
import 'package:workshop/workshop.dart';

void main() {
  group('SystemRandomSource', () {
    test('nextInt reste dans [0, exclusiveMax)', () {
      final random = SystemRandomSource(1);
      for (var i = 0; i < 200; i++) {
        final value = random.nextInt(7);
        expect(value, inInclusiveRange(0, 6));
      }
    });

    test('nextDouble reste dans [0.0, 1.0)', () {
      final random = SystemRandomSource(1);
      for (var i = 0; i < 200; i++) {
        final value = random.nextDouble();
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThan(1.0));
      }
    });

    test('la même graine rejoue la même séquence (débogage, ADR 0002)', () {
      final a = SystemRandomSource(42);
      final b = SystemRandomSource(42);
      final sequenceA = [for (var i = 0; i < 20; i++) a.nextInt(100)];
      final sequenceB = [for (var i = 0; i < 20; i++) b.nextInt(100)];
      expect(sequenceA, sequenceB);
    });

    test('génère réellement une Énigme juste via GenerateWorkshopPuzzle', () {
      // Une génération isolée peut échouer proprement sur une énigme ambiguë (ADR 0001) :
      // on vérifie que l'adapter réel permet d'en réussir au moins une parmi quelques graines,
      // plutôt que de figer le test sur une graine précise et son résultat du moment.
      final succeeded = List.generate(5, (seed) {
        final generator = GenerateWorkshopPuzzle(
          catalog: const RuleCatalog(),
          random: SystemRandomSource(seed),
        );
        final result = generator(const GenerateWorkshopPuzzleRequest(
          rowCount: 3,
          columnCount: 3,
          ruleCount: 1,
          exampleCount: 2,
          profile: GenerationProfile.intuitiveDefaults,
        ));
        return result is GenerationSucceeded;
      }).any((success) => success);

      expect(succeeded, isTrue);
    });
  });
}
