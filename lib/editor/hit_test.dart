import 'package:flutter/material.dart';
import '../models/circuit.dart';
import '../models/circuit_node.dart';
import '../models/pin.dart';
import '../models/wire.dart';

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

      // Logic from CircuitPainter._drawOrthogonalWire
      final List<Offset> points = [start];
      const minExtension = 16.0;

      if (end.dx > start.dx + 2 * minExtension) {
        final midX = (start.dx + end.dx) / 2;
        points.add(Offset(midX, start.dy));
        points.add(Offset(midX, end.dy));
      } else {
        final midY = (start.dy + end.dy) / 2;
        final outX = start.dx + minExtension;
        final inX = end.dx - minExtension;

        points.add(Offset(outX, start.dy));
        points.add(Offset(outX, midY));
        points.add(Offset(inX, midY));
        points.add(Offset(inX, end.dy));
      }
      points.add(end);

      for (int i = 0; i < points.length - 1; i++) {
        if (_distToSegment(point, points[i], points[i + 1]) <= hitThreshold) {
          return wire;
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
