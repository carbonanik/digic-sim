import 'dart:ui';
import '../circuit_node.dart';

class RGBLEDNode extends CircuitNode {
  bool r = false;
  bool g = false;
  bool b = false;

  RGBLEDNode({
    required super.id,
    required super.position,
    required super.inputPins,
    required super.outputPins,
  });

  @override
  Size get size => const Size(80, 96);

  @override
  void evaluate(List<bool> inputs) {
    if (inputs.isNotEmpty) r = inputs[0];
    if (inputs.length >= 2) g = inputs[1];
    if (inputs.length >= 3) b = inputs[2];
  }

  @override
  CircuitNode clone(String newId) {
    return RGBLEDNode(
      id: newId,
      position: position,
      inputPins: inputPins.map((p) => p.clone(newId)).toList(),
      outputPins: outputPins.map((p) => p.clone(newId)).toList(),
    );
  }

  @override
  Map<String, dynamic> toMap({bool isNested = false}) {
    return {...super.toMap(isNested: isNested), 'type': 'rgb_led'};
  }
}
