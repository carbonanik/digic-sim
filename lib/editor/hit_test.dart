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
    const samples = 10;

    for (final wire in circuit.wires) {
      final fromNode = circuit.nodes.firstWhere((n) => n.id == wire.fromNodeId);
      final toNode = circuit.nodes.firstWhere((n) => n.id == wire.toNodeId);

      final fromPin = fromNode.outputPins.firstWhere(
        (p) => p.id == wire.fromPinId,
      );
      final toPin = toNode.inputPins.firstWhere((p) => p.id == wire.toPinId);

      final start = fromNode.position + fromPin.localPosition;
      final end = toNode.position + toPin.localPosition;

      // Logic from CircuitPainter._drawSmoothWire
      final distance = (end.dx - start.dx).abs();
      final controlOffset = distance.clamp(50, 140).toDouble();

      final p1 = start;
      final cp1 = Offset(start.dx + controlOffset, start.dy);
      final cp2 = Offset(end.dx - controlOffset, end.dy);
      final p2 = end;

      Offset lastP = p1;
      for (int i = 1; i <= samples; i++) {
        final t = i / samples;
        // Cubic Bezier formula
        final nextP = Offset(
          _bezier(t, p1.dx, cp1.dx, cp2.dx, p2.dx),
          _bezier(t, p1.dy, cp1.dy, cp2.dy, p2.dy),
        );

        if (_distToSegment(point, lastP, nextP) <= hitThreshold) {
          return wire;
        }
        lastP = nextP;
      }
    }

    return null;
  }

  static double _bezier(
    double t,
    double p1,
    double cp1,
    double cp2,
    double p2,
  ) {
    return (1 - t) * (1 - t) * (1 - t) * p1 +
        3 * (1 - t) * (1 - t) * t * cp1 +
        3 * (1 - t) * t * t * cp2 +
        t * t * t * p2;
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
