import 'package:flutter/material.dart';

import 'gate_type.dart';
import 'pin.dart';

abstract class CircuitNode {
  final String id;
  Offset position;
  final List<Pin> inputPins;
  final List<Pin> outputPins;

  CircuitNode({
    required this.id,
    required this.position,
    required this.inputPins,
    required this.outputPins,
  });

  Size get size => const Size(110, 64);
  Rect get rect => position & size;

  void paint(Canvas canvas, bool isSelected);
  void evaluate(List<bool> inputs);
  bool onAction(Offset localPosition) => false;

  CircuitNode clone(String newId);
}
