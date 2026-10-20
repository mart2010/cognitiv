/// Domaine et cas d'usage du Cartographe (`games/cartographer/CONTEXT.md`). Paquet Dart pur,
/// sans import de Flutter (ADR 0005) : l'app l'assemble et fournit les Interface Adapters
/// (lecture de la Carte de base, stockage, horloge, hasard, audio).
library;

export 'src/entities/attributes.dart';
export 'src/entities/base_map.dart';
export 'src/entities/category.dart';
export 'src/entities/cartographer_answer.dart';
export 'src/entities/cartographer_level.dart';
export 'src/entities/cartographer_profile.dart';
export 'src/entities/cartographer_puzzle.dart';
export 'src/entities/facet.dart';
export 'src/entities/geo_point.dart';
export 'src/entities/geometry.dart';
export 'src/entities/item.dart';
export 'src/entities/knowledge.dart';
export 'src/entities/link.dart';
export 'src/entities/mastery.dart';
export 'src/entities/name_language.dart';
export 'src/entities/played_puzzle.dart';
export 'src/entities/recall_aid.dart';
export 'src/entities/recall_question.dart';
export 'src/entities/trial.dart';

export 'src/domain_services/decoy_placer.dart';
export 'src/domain_services/hint_builder.dart';
export 'src/domain_services/item_picker.dart';
export 'src/domain_services/placement_judge.dart';
export 'src/domain_services/text_matcher.dart';

export 'src/interface_adapters/base_map_codec.dart';
export 'src/interface_adapters/cartographer_profile_codec.dart';
export 'src/interface_adapters/mastery_codec.dart';
export 'src/interface_adapters/cartographer_puzzle_codec.dart';
export 'src/interface_adapters/system_random_source.dart';

export 'src/use_cases/compute_cartographer_score.dart';
export 'src/use_cases/compute_sequence_score.dart';
export 'src/use_cases/evaluate_cartographer_answer.dart';
export 'src/use_cases/prepare_cartographer_puzzles.dart';
export 'src/use_cases/prepare_sequence_puzzles.dart';
export 'src/use_cases/prepare_tray_puzzles.dart';
export 'src/use_cases/puzzle_preparer.dart';
export 'src/use_cases/suggest_link_kinds.dart';
export 'src/use_cases/update_mastery.dart';
export 'src/use_cases/ports/random_source.dart';
