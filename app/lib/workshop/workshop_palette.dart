import 'package:flutter/material.dart';
import 'package:workshop/workshop.dart' as workshop;

/// Interface Adapter : traduit les Couleurs du domaine vers des couleurs Flutter.
/// L'alias d'import `workshop` évite la collision de `Color` avec Flutter (`docs/PLAN.md`).
/// Palette sobre (bleu, jaune, rouge par défaut ; vert et violet pour une palette plus large) (l'habillage visuel viendra plus tard).
Color flutterColorOf(workshop.Color color) => switch (color) {
      workshop.Color.red => const Color(0xFFD6453D),
      workshop.Color.blue => const Color(0xFF2E6FD8),
      workshop.Color.green => const Color(0xFF4FA36B),
      workshop.Color.yellow => const Color(0xFFF2C230),
      workshop.Color.purple => const Color(0xFF8E67C4),
    };
