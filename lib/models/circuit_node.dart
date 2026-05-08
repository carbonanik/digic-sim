import 'package:flutter/material.dart';

import 'gate_type.dart';
import 'pin.dart';

class CircuitNode {
  final String id;
  GateType type;
  Offset position;
  bool value;

  final List<Pin> inputPins;
  final List<Pin> outputPins;

  CircuitNode({
    required this.id,
    required this.type,
    required this.position,
    this.value = false,
    required this.inputPins,
    required this.outputPins,
  });

  Rect get rect {
    return Rect.fromLTWH(position.dx, position.dy, 110, 64);
  }
}
