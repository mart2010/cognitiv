import 'package:flutter/material.dart';
import 'package:workshop/workshop.dart' as workshop;

import '../audio/game_sounds.dart';
import 'matrix_view.dart';
import 'workshop_palette.dart';

/// Mode « construction libre » : le joueur compose sa réponse sur une grille d'abord
/// entièrement vide. Il choisit un pinceau (Forme + Couleur, ou vide) puis touche les
/// cases à peindre : un seul geste par case. Aucun Rôle de case vide n'est proposé : le
/// vide générique reprend le Rôle des vides de l'Énigme (`emptyRole`), qui est unique
/// (voir `GenerateWorkshopPuzzle`), pour ne rien révéler de la Règle.
class ConstructAnswerView extends StatefulWidget {
  final int rowCount;
  final int columnCount;
  final workshop.EmptyCellRole emptyRole;
  final bool enabled;
  final GameSounds sounds;
  final void Function(workshop.Matrix answer) onSubmit;

  const ConstructAnswerView({
    super.key,
    required this.rowCount,
    required this.columnCount,
    required this.emptyRole,
    required this.onSubmit,
    this.enabled = true,
    this.sounds = const SilentGameSounds(),
  });

  @override
  State<ConstructAnswerView> createState() => _ConstructAnswerViewState();
}

class _ConstructAnswerViewState extends State<ConstructAnswerView> {
  static const _paintableShapes = [
    workshop.Shape.round,
    workshop.Shape.square,
    workshop.Shape.cross,
    workshop.Shape.empty,
  ];

  late int _rows = widget.rowCount;
  late int _columns = widget.columnCount;
  late workshop.Matrix _grid = _blankGrid();
  var _brushShape = workshop.Shape.round;
  var _brushColor = workshop.Color.values.first;

  workshop.Matrix _blankGrid() =>
      workshop.Matrix.generate(_rows, _columns, (_, _) => workshop.Cell.empty(widget.emptyRole));

  workshop.Cell get _brush => _brushShape == workshop.Shape.empty
      ? workshop.Cell.empty(widget.emptyRole)
      : workshop.Cell.filled(_brushShape, _brushColor);

  void _paintCell(int row, int column) {
    if (!widget.enabled) return;
    widget.sounds.tap();
    setState(() => _grid = _grid.withCell(row, column, _brush));
  }

  /// Permuter lignes et colonnes : certaines Règles (Transposition) changent les
  /// dimensions d'une grille rectangulaire. Proposé pour toute grille non carrée, que la
  /// Règle change les dimensions ou non, donc sans rien trahir.
  void _swapDimensions() => setState(() {
    final rows = _rows;
    _rows = _columns;
    _columns = rows;
    _grid = _blankGrid();
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: MatrixView(
            key: const Key('construct-grid'),
            matrix: _grid,
            cellSize: 44,
            onCellTap: widget.enabled ? _paintCell : null,
          ),
        ),
        if (widget.enabled) ...[
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [for (final shape in _paintableShapes) _shapeButton(scheme, shape)],
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: _brushShape == workshop.Shape.empty ? 0.3 : 1,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [for (final color in workshop.Color.values) _colorButton(scheme, color)],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              if (widget.rowCount != widget.columnCount)
                TextButton.icon(
                  key: const Key('swap-dimensions'),
                  onPressed: _swapDimensions,
                  icon: const Icon(Icons.screen_rotation_alt),
                  label: Text('$_rows × $_columns'),
                ),
              TextButton(
                key: const Key('clear-grid'),
                onPressed: () => setState(() => _grid = _blankGrid()),
                child: const Text('Tout vider'),
              ),
            ],
          ),
          FilledButton(
            key: const Key('submit-construction'),
            onPressed: () => widget.onSubmit(_grid),
            child: const Text('Valider'),
          ),
        ],
      ],
    );
  }

  Widget _shapeButton(ColorScheme scheme, workshop.Shape shape) {
    final selected = _brushShape == shape;
    final preview = shape == workshop.Shape.empty
        ? workshop.Cell.empty(widget.emptyRole)
        : workshop.Cell.filled(shape, _brushColor);
    return InkWell(
      key: Key('brush-shape-${shape.name}'),
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _brushShape = shape),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: MatrixView(
          matrix: workshop.Matrix([
            [preview],
          ]),
          cellSize: 36,
        ),
      ),
    );
  }

  Widget _colorButton(ColorScheme scheme, workshop.Color color) {
    final selected = _brushColor == color;
    return InkWell(
      key: Key('brush-color-${color.name}'),
      customBorder: const CircleBorder(),
      onTap: () => setState(() {
        _brushColor = color;
        if (_brushShape == workshop.Shape.empty) {
          _brushShape = workshop.Shape.round;
        }
      }),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: flutterColorOf(color),
          shape: BoxShape.circle,
          border: Border.all(color: selected ? scheme.onSurface : Colors.transparent, width: 3),
        ),
      ),
    );
  }
}
