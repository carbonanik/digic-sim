import 'dart:collection';
import 'dart:ui';
import '../circuit_node.dart';

class WaveformNode extends CircuitNode {
  static const int maxHistory = 100;
  final List<ListQueue<bool>> histories;

  WaveformNode({
    required super.id,
    required super.position,
    required super.inputPins,
    required super.outputPins,
  }) : histories = List.generate(
         inputPins.length,
         (_) => ListQueue<bool>(maxHistory),
       ) {
    // Pre-fill with false
    for (var history in histories) {
      for (int i = 0; i < maxHistory; i++) {
        history.addLast(false);
      }
    }
  }

  @override
  Size get size => Size(200, 32.0 + inputPins.length * 32.0);

  @override
  void evaluate(List<bool> inputs) {
    for (int i = 0; i < histories.length; i++) {
      if (i < inputs.length) {
        histories[i].removeFirst();
        histories[i].addLast(inputs[i]);
      }
    }
  }

  @override
  CircuitNode clone(String newId) {
    return WaveformNode(
      id: newId,
      position: position,
      inputPins: inputPins.map((p) => p.clone(newId)).toList(),
      outputPins: outputPins.map((p) => p.clone(newId)).toList(),
    );
  }

  @override
  Map<String, dynamic> toMap({bool isNested = false}) {
    return {...super.toMap(isNested: isNested), 'type': 'waveform'};
  }
}
