import 'package:flutter/material.dart';
import 'package:workshop/workshop.dart' as workshop;

/// Interface Adapter : traduit les Couleurs du domaine vers des couleurs Flutter.
/// L'alias d'import `workshop` évite la collision de `Color` avec Flutter (`docs/PLAN.md`).
/// Palette sobre, provisoire (l'habillage visuel viendra plus tard).
Color flutterColorOf(workshop.Color color) => switch (color) {
      workshop.Color.red => const Color(0xFFD9534F),
      workshop.Color.blue => const Color(0xFF4A7BD0),
      workshop.Color.green => const Color(0xFF4FA36B),
      workshop.Color.yellow => const Color(0xFFE0B13A),
      workshop.Color.purple => const Color(0xFF8E67C4),
    };
