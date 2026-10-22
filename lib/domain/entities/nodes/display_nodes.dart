import 'dart:ui';
import '../circuit_node.dart';

class SegmentDisplayNode extends CircuitNode {
  final List<bool> segments = List.filled(7, false);

  SegmentDisplayNode({
    required super.id,
    required super.position,
    required super.inputPins,
    required super.outputPins,
  });

  @override
  Size get size => const Size(80, 128); // Larger vertical size for display

  @override
  void evaluate(List<bool> inputs) {
    for (int i = 0; i < segments.length; i++) {
      if (i < inputs.length) {
        segments[i] = inputs[i];
      } else {
        segments[i] = false;
      }
    }
  }

  @override
  CircuitNode clone(String newId) {
    return SegmentDisplayNode(
      id: newId,
      position: position,
      inputPins: inputPins.map((p) => p.clone(newId)).toList(),
      outputPins: outputPins.map((p) => p.clone(newId)).toList(),
    );
  }

  @override
  Map<String, dynamic> toMap({bool isNested = false}) {
    return {...super.toMap(isNested: isNested), 'type': 'segment_display'};
  }
}
