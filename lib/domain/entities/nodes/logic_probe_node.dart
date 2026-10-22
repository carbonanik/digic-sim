import 'dart:ui';
import '../circuit_node.dart';

class LogicProbeNode extends CircuitNode {
  bool value = false;

  LogicProbeNode({
    required super.id,
    required super.position,
    required super.inputPins,
    required super.outputPins,
  });

  @override
  Size get size => const Size(80, 64);

  @override
  void evaluate(List<bool> inputs) {
    if (inputs.isNotEmpty) {
      value = inputs[0];
    }
  }

  @override
  CircuitNode clone(String newId) {
    return LogicProbeNode(
      id: newId,
      position: position,
      inputPins: inputPins.map((p) => p.clone(newId)).toList(),
      outputPins: outputPins.map((p) => p.clone(newId)).toList(),
    );
  }

  @override
  Map<String, dynamic> toMap({bool isNested = false}) {
    return {...super.toMap(isNested: isNested), 'type': 'logic_probe'};
  }
}
