import 'package:flutter/material.dart';

import '../models/circuit.dart';
import '../models/circuit_node.dart';
import '../models/pin.dart';

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
}

class PinHit {
  final CircuitNode node;
  final Pin pin;

  PinHit({required this.node, required this.pin});
}
