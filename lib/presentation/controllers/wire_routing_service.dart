import 'package:flutter/material.dart';
import 'package:digital_logic_sim_2/core/utils/extensions.dart';
import 'package:digital_logic_sim_2/core/utils/pathfinder.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit_node.dart';
import 'package:digital_logic_sim_2/domain/entities/wire.dart';

class WireRoutingService {
  Map<String, List<Offset>>? initialDragWaypoints;

  void clearDragWaypoints() {
    initialDragWaypoints = null;
  }

  List<Offset> simplifyOrthogonalPoints(List<Offset> points) {
    if (points.length <= 2) return points;

    final result = <Offset>[];

    for (final point in points) {
      if (result.isNotEmpty && (result.last - point).distance < 0.1) {
        continue;
      }

      result.add(point);
    }

    bool changed = true;

    while (changed) {
      changed = false;

      for (int i = 1; i < result.length - 1; i++) {
        final a = result[i - 1];
        final b = result[i];
        final c = result[i + 1];

        final sameVertical =
            (a.dx - b.dx).abs() < 0.1 && (b.dx - c.dx).abs() < 0.1;

        final sameHorizontal =
            (a.dy - b.dy).abs() < 0.1 && (b.dy - c.dy).abs() < 0.1;

        if (sameVertical || sameHorizontal) {
          result.removeAt(i);
          changed = true;
          break;
        }
      }
    }

    return result;
  }

  void recalculatePaths({
    required Circuit circuit,
    required Set<String> selectedNodeIds,
    required bool pathsDirty,
    required Function(bool) setPathsDirty,
    List<String>? onlyWireIds,
    Offset? translationDelta,
  }) {
    if (!pathsDirty && onlyWireIds == null) return;

    final obstacles = circuit.nodes.toObstacles();
    final allSegments = <WireSegment>{};

    for (int i = 0; i < circuit.wires.length; i++) {
      final wire = circuit.wires[i];
      final start = getWireStart(circuit, wire);
      final end = getWireEnd(circuit, wire);

      if (start == null || end == null) continue;

      final shouldRecalculate =
          onlyWireIds != null && onlyWireIds.contains(wire.id);

      if (shouldRecalculate) {
        final fromMoved = selectedNodeIds.contains(wire.fromNodeId);
        final toMoved = selectedNodeIds.contains(wire.toNodeId);

        if (fromMoved && toMoved) {
          if (wire.waypoints.isEmpty) {
            final points = PathFinder.findPath(
              start: start,
              end: end,
              obstacles: obstacles,
              existingSegments: allSegments,
            );
            final newWaypoints = points.length <= 2
                ? <Offset>[]
                : points.sublist(1, points.length - 1);
            circuit.wires[i] = wire.copyWith(waypoints: newWaypoints);
          } else if (translationDelta != null) {
            final newWaypoints = wire.waypoints
                .map((wp) => wp + translationDelta)
                .toList();
            circuit.wires[i] = wire.copyWith(waypoints: newWaypoints);
          }
        } else if (fromMoved || toMoved) {
          initialDragWaypoints ??= {
            for (final w in circuit.wires) w.id: List<Offset>.from(w.waypoints),
          };

          final baseWaypoints =
              initialDragWaypoints![wire.id] ?? wire.waypoints;

          bool crossedSides = false;
          if (baseWaypoints.isNotEmpty) {
            if (fromMoved && baseWaypoints.first.dx < start.dx) {
              crossedSides = true;
            } else if (toMoved && baseWaypoints.last.dx > end.dx) {
              crossedSides = true;
            }
          }

          if (baseWaypoints.isEmpty || crossedSides) {
            final points = PathFinder.findPath(
              start: start,
              end: end,
              obstacles: obstacles,
              existingSegments: allSegments,
            );
            final newWaypoints = points.length <= 2
                ? <Offset>[]
                : points.sublist(1, points.length - 1);
            circuit.wires[i] = wire.copyWith(waypoints: newWaypoints);
          } else {
            List<Offset> waypoints = List<Offset>.from(baseWaypoints);

            if (fromMoved) {
              final target = waypoints.length > 1 ? waypoints[1] : end;
              final subPath = PathFinder.findPath(
                start: start,
                end: target,
                obstacles: obstacles,
                existingSegments: allSegments,
              );
              final newSubWaypoints = subPath.length <= 2
                  ? <Offset>[]
                  : subPath.sublist(1, subPath.length - 1);

              if (waypoints.length > 1) {
                waypoints = [...newSubWaypoints, ...waypoints.sublist(1)];
              } else {
                waypoints = newSubWaypoints;
              }
            }

            if (toMoved) {
              final startTarget = waypoints.length > 1
                  ? waypoints[waypoints.length - 2]
                  : start;

              final subPath = PathFinder.findPath(
                start: startTarget,
                end: end,
                obstacles: obstacles,
                existingSegments: allSegments,
              );
              final newSubWaypoints = subPath.length <= 2
                  ? <Offset>[]
                  : subPath.sublist(1, subPath.length - 1);

              if (waypoints.length > 1) {
                waypoints = [
                  ...waypoints.sublist(0, waypoints.length - 1),
                  ...newSubWaypoints,
                ];
              } else {
                waypoints = newSubWaypoints;
              }
            }

            final fullPoints = [start, ...waypoints, end];
            final simplifiedFull = simplifyOrthogonalPoints(fullPoints);
            final finalWaypoints = simplifiedFull.length <= 2
                ? <Offset>[]
                : simplifiedFull.sublist(1, simplifiedFull.length - 1);

            circuit.wires[i] = wire.copyWith(waypoints: finalWaypoints);
          }
        }
      } else if (wire.waypoints.isEmpty) {
        final points = PathFinder.findPath(
          start: start,
          end: end,
          obstacles: obstacles,
          existingSegments: allSegments,
        );

        final newWaypoints = points.length <= 2
            ? <Offset>[]
            : points.sublist(1, points.length - 1);

        circuit.wires[i] = wire.copyWith(waypoints: newWaypoints);
      }

      final points = [start, ...circuit.wires[i].waypoints, end];
      for (int j = 0; j < points.length - 1; j++) {
        addSegments(allSegments, points[j], points[j + 1]);
      }
    }
    if (onlyWireIds == null) {
      setPathsDirty(false);
    }
  }

  void addSegments(Set<WireSegment> segments, Offset p1, Offset p2) {
    const gridSize = 16.0;
    final dist = (p1 - p2).distance;
    if (dist < 0.1) return;

    final dir = (p2 - p1) / dist;
    final steps = (dist / gridSize).round();

    for (int i = 0; i < steps; i++) {
      final s1 = p1 + dir * (i * gridSize);
      final s2 = p1 + dir * ((i + 1) * gridSize);
      segments.add(WireSegment(s1, s2));
    }
  }

  Offset? getWireStart(Circuit circuit, Wire wire) {
    final node = findNode(circuit, wire.fromNodeId);
    if (node == null) return null;

    final pin = node.outputPins
        .where((p) => p.id == wire.fromPinId)
        .firstOrNull;
    if (pin == null) return null;

    return node.position + pin.localPosition;
  }

  Offset? getWireEnd(Circuit circuit, Wire wire) {
    final node = findNode(circuit, wire.toNodeId);
    if (node == null) return null;

    final pin = node.inputPins.where((p) => p.id == wire.toPinId).firstOrNull;
    if (pin == null) return null;

    return node.position + pin.localPosition;
  }

  CircuitNode? findNode(Circuit circuit, String id) {
    for (final node in circuit.nodes) {
      if (node.id == id) return node;
    }
    return null;
  }
}
