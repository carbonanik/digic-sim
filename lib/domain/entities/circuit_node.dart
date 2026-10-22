import 'dart:math';

import 'dart:ui';

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

  Size get size => const Size(112, 64);
  Offset get randomPosition =>
      position +
      Offset(Random().nextInt(10).toDouble(), Random().nextInt(10).toDouble());
  Rect get rect => position & size;

  void evaluate(List<bool> inputs);
  bool onAction(Offset localPosition) => false;

  CircuitNode clone(String newId);

  Map<String, dynamic> toMap({bool isNested = false}) {
    return {
      'id': id,
      'position': {'dx': position.dx, 'dy': position.dy},
      'inputPins': inputPins.map((p) => p.toMap()).toList(),
      'outputPins': outputPins.map((p) => p.toMap()).toList(),
    };
  }
}
