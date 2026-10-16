import 'package:flutter/material.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit_node.dart';
import 'package:digital_logic_sim_2/domain/entities/pin.dart';
import 'package:digital_logic_sim_2/domain/entities/wire.dart';

class HitTesting {
  static CircuitNode? findNodeAt(Circuit circuit, Offset point) {
    for (final node in circuit.nodes.reversed) {
      if (node.rect.contains(point)) {
        return node;
      }
    }

    return null;
  }

  static List<CircuitNode> findNodesInRect(Circuit circuit, Rect rect) {
    return circuit.nodes.where((node) {
      return rect.overlaps(node.rect);
    }).toList();
  }

  static PinHit? findPinAt(Circuit circuit, Offset point) {
    const hitRadius = 12.0;

    for (final node in circuit.nodes.reversed) {
      final pins = [...node.inputPins, ...node.outputPins];

      for (final pin in pins) {
        final pinPosition = node.position + pin.localPosition;
        final distance = (pinPosition - point).distance;

        if (distance <= hitRadius) {
          return PinHit(node: node, pin: pin);
        }
      }
    }

    return null;
  }

  static Wire? findWireAt(Circuit circuit, Offset point) {
    return findWireHitAt(circuit, point)?.wire;
  }

  static WireHit? findWireHitAt(Circuit circuit, Offset point) {
    const hitThreshold = 10.0;

    for (final wire in circuit.wires) {
      final fromNode = circuit.nodes.firstWhere((n) => n.id == wire.fromNodeId);
      final toNode = circuit.nodes.firstWhere((n) => n.id == wire.toNodeId);

      final fromPin = fromNode.outputPins.firstWhere(
        (p) => p.id == wire.fromPinId,
      );
      final toPin = toNode.inputPins.firstWhere((p) => p.id == wire.toPinId);

      final start = fromNode.position + fromPin.localPosition;
      final end = toNode.position + toPin.localPosition;

      final points = wire.getPathPoints(start, end);

      for (int i = 0; i < points.length - 1; i++) {
        if (_distToSegment(point, points[i], points[i + 1]) <= hitThreshold) {
          return WireHit(wire: wire, segmentIndex: i);
        }
      }
    }

    return null;
  }

  static double _distToSegment(Offset p, Offset v, Offset w) {
    final l2 = (v - w).distanceSquared;
    if (l2 == 0.0) return (p - v).distance;
    final t =
        ((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) / l2;
    if (t < 0.0) return (p - v).distance;
    if (t > 1.0) return (p - w).distance;
    final projection = v + (w - v) * t;
    return (p - projection).distance;
  }
}

class PinHit {
  final CircuitNode node;
  final Pin pin;

  PinHit({required this.node, required this.pin});
}

class PinSelection {
  final CircuitNode node;
  final Pin pin;

  PinSelection({required this.node, required this.pin});
}

class WireHit {
  final Wire wire;
  final int segmentIndex;

  WireHit({required this.wire, required this.segmentIndex});
}
