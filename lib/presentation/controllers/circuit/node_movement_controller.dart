import 'package:flutter/material.dart';

import 'circuit_session.dart';

class NodeMovementController {
  final CircuitSession session;
  Offset _dragAccumulator = Offset.zero;

  NodeMovementController(this.session);

  void resetDragAccumulator() {
    _dragAccumulator = Offset.zero;
  }

  void endNodeMove() {
    session.routing.clearDragWaypoints();
    if (session.editor.selectedNodeIds.isNotEmpty) {
      session.pathsDirty = true;
      session.recalculatePaths();
      session.documentChanged();
    }
  }

  void moveSelectedNodes(Offset delta) {
    if (session.editor.selectedNodeIds.isEmpty) return;

    if (!session.snapToGridEnabled) {
      for (final node in session.circuit.nodes) {
        if (session.editor.selectedNodeIds.contains(node.id)) {
          node.position += delta;
        }
      }
      final affectedWireIds = session.circuit.wires
          .where(
            (w) =>
                session.editor.selectedNodeIds.contains(w.fromNodeId) ||
                session.editor.selectedNodeIds.contains(w.toNodeId),
          )
          .map((w) => w.id)
          .toList();

      session.pathsDirty = true;
      session.recalculatePaths(
        onlyWireIds: affectedWireIds,
        translationDelta: delta,
      );
      session.repaintCircuit();
      return;
    }

    _dragAccumulator += delta;
    final gridSize = session.grid.size;
    final int stepsX = (_dragAccumulator.dx / gridSize).round();
    final int stepsY = (_dragAccumulator.dy / gridSize).round();

    if (stepsX != 0 || stepsY != 0) {
      final snappedDelta = Offset(stepsX * gridSize, gridSize * stepsY);
      for (final node in session.circuit.nodes) {
        if (session.editor.selectedNodeIds.contains(node.id)) {
          node.position = session.grid.snap(node.position) + snappedDelta;
        }
      }
      _dragAccumulator -= snappedDelta;

      final affectedWireIds = session.circuit.wires
          .where(
            (w) =>
                session.editor.selectedNodeIds.contains(w.fromNodeId) ||
                session.editor.selectedNodeIds.contains(w.toNodeId),
          )
          .map((w) => w.id)
          .toList();

      session.recalculatePaths(
        onlyWireIds: affectedWireIds,
        translationDelta: snappedDelta,
      );
      session.repaintCircuit();
    }
  }
}
