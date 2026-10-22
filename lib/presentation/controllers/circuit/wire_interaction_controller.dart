import 'package:digital_logic_sim_2/core/utils/extensions.dart';
import 'package:digital_logic_sim_2/core/utils/pathfinder.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit_node.dart';
import 'package:digital_logic_sim_2/domain/entities/pin.dart';
import 'package:digital_logic_sim_2/domain/entities/wire.dart';
import 'package:digital_logic_sim_2/presentation/canvas/hit_test.dart';
import 'package:digital_logic_sim_2/presentation/controllers/commands/circuit_command.dart';
import 'package:flutter/material.dart';

import 'circuit_session.dart';

class WireInteractionController {
  final CircuitSession session;

  WireInteractionController(this.session);

  void startWireDrag(WireHit hit, Offset mousePos) {
    session.editor.draggedWireHit = hit;

    final wire = hit.wire;
    if (wire.waypoints.isEmpty) {
      final start = session.routing.getWireStart(session.circuit, wire);
      final end = session.routing.getWireEnd(session.circuit, wire);
      if (start != null && end != null) {
        final points = PathFinder.findPath(
          start: start,
          end: end,
          obstacles: session.circuit.nodes.toObstacles(),
        );
        session.editor.initialWaypoints = points.length <= 2
            ? []
            : points.sublist(1, points.length - 1);
      } else {
        session.editor.initialWaypoints = [];
      }
    } else {
      session.editor.initialWaypoints = List.from(wire.waypoints);
    }
    session.uiChanged();
  }

  void updateWireDrag(Offset mousePos) {
    if (session.editor.draggedWireHit == null ||
        session.editor.initialWaypoints == null) {
      return;
    }

    final snappedMouse = session.grid.snap(mousePos);
    final wire = session.editor.draggedWireHit!.wire;
    final segmentIndex = session.editor.draggedWireHit!.segmentIndex;

    final start = session.routing.getWireStart(session.circuit, wire);
    final end = session.routing.getWireEnd(session.circuit, wire);

    if (start == null || end == null) return;

    final points = [start, ...session.editor.initialWaypoints!, end];

    if (segmentIndex < 0 || segmentIndex >= points.length - 1) return;

    final p1 = points[segmentIndex];
    final p2 = points[segmentIndex + 1];

    final isHorizontal = (p1.dy - p2.dy).abs() < 0.1;
    final isVertical = (p1.dx - p2.dx).abs() < 0.1;

    if (!isHorizontal && !isVertical) return;

    final List<Offset> newPoints;

    if (isHorizontal) {
      final newY = snappedMouse.dy;
      newPoints = [
        ...points.take(segmentIndex + 1),
        Offset(p1.dx, newY),
        Offset(p2.dx, newY),
        ...points.skip(segmentIndex + 1),
      ];
    } else {
      final newX = snappedMouse.dx;
      newPoints = [
        ...points.take(segmentIndex + 1),
        Offset(newX, p1.dy),
        Offset(newX, p2.dy),
        ...points.skip(segmentIndex + 1),
      ];
    }

    final simplifiedPoints = session.routing.simplifyOrthogonalPoints(
      newPoints,
    );

    final newWaypoints = simplifiedPoints.length <= 2
        ? <Offset>[]
        : simplifiedPoints.sublist(1, simplifiedPoints.length - 1);

    final wireIndex = session.circuit.wires.indexWhere((w) => w.id == wire.id);

    if (wireIndex != -1) {
      session.circuit.wires[wireIndex] = wire.copyWith(waypoints: newWaypoints);
      session.pathsDirty = true;
      session.recalculatePaths();
      session.repaintCircuit();
    }
  }

  void endWireDrag() {
    if (session.editor.draggedWireHit != null) {
      if (session.editor.initialWaypoints != null) {
        final currentWaypoints = session.circuit.wires
            .firstWhere(
              (wire) => wire.id == session.editor.draggedWireHit!.wire.id,
            )
            .waypoints;
        session.history.push(
          UpdateWireWaypointsCommand(
            wireId: session.editor.draggedWireHit!.wire.id,
            oldWaypoints: session.editor.initialWaypoints!,
            newWaypoints: List.from(currentWaypoints),
          ),
        );
      }
      session.editor.draggedWireHit = null;
      session.editor.initialWaypoints = null;
      session.pathsDirty = true;
      session.recalculatePaths();
      session.documentChanged();
    }
  }

  void resetWirePath(String wireId) {
    final wireIndex = session.circuit.wires.indexWhere((w) => w.id == wireId);
    if (wireIndex != -1) {
      final oldWire = session.circuit.wires[wireIndex];
      session.circuit.wires[wireIndex] = oldWire.copyWith(waypoints: []);
      session.pathsDirty = true;
      session.recalculatePaths();
      session.uiChanged();
    }
  }

  void startWire(CircuitNode node, Pin pin) {
    if (pin.isInput) return;

    session.editor.wireStart = PinSelection(node: node, pin: pin);
    session.editor.temporaryWireEnd = node.position + pin.localPosition;
    session.repaintOverlay();
  }

  void updateTemporaryWire(Offset point) {
    session.editor.temporaryWireEnd = session.grid.snap(point);
    session.repaintOverlay();
  }

  void finishWire(CircuitNode node, Pin pin) {
    if (session.editor.wireStart == null) return;
    if (!pin.isInput) return;

    final start = session.editor.wireStart!;

    if (start.node.id == node.id) {
      cancelWire();
      return;
    }

    final inputAlreadyUsed = session.circuit.wires.any((wire) {
      return wire.toNodeId == node.id && wire.toPinId == pin.id;
    });

    if (inputAlreadyUsed) {
      cancelWire();
      return;
    }

    final wire = Wire(
      id: UniqueKey().toString(),
      fromNodeId: start.node.id,
      fromPinId: start.pin.id,
      toNodeId: node.id,
      toPinId: pin.id,
    );
    session.circuit.wires.add(wire);

    session.history.push(AddWiresCommand([wire]));

    session.editor.wireStart = null;
    session.editor.temporaryWireEnd = null;

    session.simulate();
    session.pathsDirty = true;
    session.recalculatePaths();
    session.documentChanged();
  }

  void cancelWire() {
    session.editor.wireStart = null;
    session.editor.temporaryWireEnd = null;
    session.repaintOverlay();
  }
}
