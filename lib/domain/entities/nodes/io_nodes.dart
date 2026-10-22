import 'dart:ui';
import '../circuit_node.dart';

class InputNode extends CircuitNode {
  bool value;
  String label;

  InputNode({
    required super.id,
    required super.position,
    required super.inputPins,
    required super.outputPins,
    this.value = false,
    this.label = '',
  });

  @override
  void evaluate(List<bool> inputs) {
    if (outputPins.isNotEmpty) {
      outputPins.first.value = value;
    }
  }

  @override
  bool onAction(Offset localPosition) {
    // Toggle value when clicked
    value = !value;
    return true;
  }

  @override
  CircuitNode clone(String newId) {
    return InputNode(
      id: newId,
      position: position,
      value: value,
      label: label,
      inputPins: inputPins.map((p) => p.clone(newId)).toList(),
      outputPins: outputPins.map((p) => p.clone(newId)).toList(),
    );
  }

  @override
  Map<String, dynamic> toMap({bool isNested = false}) {
    return {
      ...super.toMap(isNested: isNested),
      'type': 'input',
      'value': value,
      'label': label,
    };
  }
}

class OutputNode extends CircuitNode {
  bool value;
  String label;

  OutputNode({
    required super.id,
    required super.position,
    required super.inputPins,
    required super.outputPins,
    this.value = false,
    this.label = '',
  });

  @override
  void evaluate(List<bool> inputs) {
    value = inputs.isNotEmpty ? inputs.first : false;
    if (outputPins.isNotEmpty) {
      outputPins.first.value = value;
    }
  }

  @override
  CircuitNode clone(String newId) {
    return OutputNode(
      id: newId,
      position: position,
      value: value,
      label: label,
      inputPins: inputPins.map((p) => p.clone(newId)).toList(),
      outputPins: outputPins.map((p) => p.clone(newId)).toList(),
    );
  }

  @override
  Map<String, dynamic> toMap({bool isNested = false}) {
    return {
      ...super.toMap(isNested: isNested),
      'type': 'output',
      'value': value,
      'label': label,
    };
  }
}
