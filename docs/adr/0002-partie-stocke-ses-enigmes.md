# Une partie stocke ses énigmes générées, pas une graine

Pour reprendre une partie en pause, on stocke dès son début les énigmes elles-mêmes (petites : quelques exemples et 4 réponses) plutôt qu'une graine de génération. Une mise à jour de l'app qui changerait le générateur ou le catalogue de règles donnerait sinon d'autres énigmes, voire des énigmes injustes (voir ADR 0001). La graine peut être conservée en plus, pour le débogage.

## Considered Options

- **Graine seule** : très peu de données, mais la reprise dépend de la stabilité du générateur entre versions.

## Consequences

- Pour une séance, dont la fin est une durée, les énigmes sont générées et stockées au fur et à mesure et non d'un bloc.
- Une partie occupe plus de place dans le profil local, mais reste petite.
- La même partie peut être rejouée à l'identique.
