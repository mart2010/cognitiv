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
  ];

  late int _rows = widget.rowCount;
  late int _columns = widget.columnCount;
  late workshop.Matrix _grid = _blankGrid();
  var _brushShape = workshop.Shape.round;
  var _brushColor = workshop.Color.defaultPalette.first;

  workshop.Matrix _blankGrid() =>
      workshop.Matrix.generate(_rows, _columns, (_, _) => workshop.Cell.empty(widget.emptyRole));

  workshop.Cell get _brush => workshop.Cell.filled(_brushShape, _brushColor);

  /// Toucher une case la peint avec le pinceau ; la retoucher avec le même pinceau la
  /// vide. Pas de pinceau « vide » : une case qui doit rester vide, on ne la remplit pas.
  void _paintCell(int row, int column) {
    if (!widget.enabled) return;
    widget.sounds.tap();
    final isSameAsBrush = _grid.cellAt(row, column) == _brush;
    final next = isSameAsBrush ? workshop.Cell.empty(widget.emptyRole) : _brush;
    setState(() => _grid = _grid.withCell(row, column, next));
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

  /// Grille à gauche, pinceau (formes puis couleurs) à droite, actions dessous : compact,
  /// pour que l'Énigme tienne à l'écran sans défilement.
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
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
              const SizedBox(width: 16),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final shape in _paintableShapes) ...[
                        if (shape != _paintableShapes.first) const SizedBox(width: 8),
                        _shapeButton(scheme, shape),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final color in workshop.Color.defaultPalette) _colorButton(scheme, color),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
        if (widget.enabled) ...[
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              if (widget.rowCount != widget.columnCount)
                TextButton(
                  key: const Key('swap-dimensions'),
                  onPressed: _swapDimensions,
                  child: Text('Permuter $_rows × $_columns'),
                ),
              TextButton(
                key: const Key('clear-grid'),
                onPressed: () => setState(() => _grid = _blankGrid()),
                child: const Text('Effacer tout'),
              ),
              FilledButton(
                key: const Key('submit-construction'),
                onPressed: () => widget.onSubmit(_grid),
                child: const Text('Valider la réponse'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _shapeButton(ColorScheme scheme, workshop.Shape shape) {
    final selected = _brushShape == shape;
    return InkWell(
      key: Key('brush-shape-${shape.name}'),
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _brushShape = shape),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: MatrixView(
          matrix: workshop.Matrix([
            [workshop.Cell.filled(shape, _brushColor)],
          ]),
          cellSize: 34,
        ),
      ),
    );
  }

  Widget _colorButton(ColorScheme scheme, workshop.Color color) {
    final selected = _brushColor == color;
    return InkWell(
      key: Key('brush-color-${color.name}'),
      customBorder: const CircleBorder(),
      onTap: () => setState(() => _brushColor = color),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: flutterColorOf(color),
          shape: BoxShape.circle,
          border: Border.all(color: selected ? scheme.onSurface : Colors.transparent, width: 3),
        ),
      ),
    );
  }
}
