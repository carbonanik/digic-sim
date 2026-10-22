import 'dart:ui';
import '../circuit_node.dart';

class ClockNode extends CircuitNode {
  bool value = false;
  double frequency = 1.0; // Hz
  DateTime lastToggleTime = DateTime.now();
  static const List<double> frequencies = [0.5, 1.0, 2.0, 5.0, 10.0, 20.0];

  ClockNode({
    required super.id,
    required super.position,
    required super.inputPins,
    required super.outputPins,
    this.value = false,
  });

  @override
  void evaluate(List<bool> inputs) {
    if (outputPins.isNotEmpty) {
      outputPins.first.value = value;
    }
  }

  @override
  bool onAction(Offset localPosition) {
    int currentIndex = frequencies.indexOf(frequency);
    if (currentIndex == -1) currentIndex = 0;

    int nextIndex = (currentIndex + 1) % frequencies.length;
    frequency = frequencies[nextIndex];
    return true;
  }

  @override
  CircuitNode clone(String newId) {
    return ClockNode(
      id: newId,
      position: position,
      value: value,
      inputPins: inputPins.map((p) => p.clone(newId)).toList(),
      outputPins: outputPins.map((p) => p.clone(newId)).toList(),
    )..frequency = frequency;
  }

  @override
  Map<String, dynamic> toMap({bool isNested = false}) {
    return {
      ...super.toMap(isNested: isNested),
      'type': 'clock',
      'value': value,
      'frequency': frequency,
    };
  }
}
