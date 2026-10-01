/// Domaine et cas d'usage de L'atelier (`games/workshop/CONTEXT.md`). Paquet Dart pur,
/// sans import de Flutter (ADR 0005) : l'app l'assemble et fournit les Interface
/// Adapters (stockage, horloge, hasard, audio).
library;

export 'src/entities/cell.dart';
export 'src/entities/color.dart';
export 'src/entities/empty_cell_role.dart';
export 'src/entities/generation_profile.dart';
export 'src/entities/matrix.dart';
export 'src/entities/rule.dart';
export 'src/entities/rule_catalog.dart';
export 'src/entities/rule_family.dart';
export 'src/entities/shape.dart';
export 'src/entities/workshop_answer.dart';
export 'src/entities/workshop_puzzle.dart';

export 'src/domain_services/workshop_puzzle_solver.dart';

export 'src/use_cases/compute_workshop_score.dart';
export 'src/use_cases/evaluate_workshop_answer.dart';
export 'src/use_cases/generate_workshop_puzzle.dart';
export 'src/use_cases/ports/random_source.dart';
