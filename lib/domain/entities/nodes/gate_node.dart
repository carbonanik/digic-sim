import '../circuit_node.dart';

enum Gate { and, or, not, nand, nor, xor }

class GateNode extends CircuitNode {
  final Gate type;

  GateNode({
    required super.id,
    required super.position,
    required super.inputPins,
    required super.outputPins,
    required this.type,
  });

  @override
  void evaluate(List<bool> inputs) {
    bool result = false;
    switch (type) {
      case Gate.and:
        result = inputs.length >= 2 && inputs.every((v) => v);
        break;
      case Gate.or:
        result = inputs.any((v) => v);
        break;
      case Gate.not:
        result = inputs.isNotEmpty ? !inputs.first : true;
        break;
      case Gate.nand:
        result = !(inputs.length >= 2 && inputs.every((v) => v));
        break;
      case Gate.nor:
        result = !inputs.any((v) => v);
        break;
      case Gate.xor:
        result = inputs.where((v) => v).length.isOdd;
        break;
    }

    if (outputPins.isNotEmpty) {
      outputPins.first.value = result;
    }
  }

  @override
  CircuitNode clone(String newId) {
    return GateNode(
      id: newId,
      position: position,
      type: type,
      inputPins: inputPins.map((p) => p.clone(newId)).toList(),
      outputPins: outputPins.map((p) => p.clone(newId)).toList(),
    );
  }

  @override
  Map<String, dynamic> toMap({bool isNested = false}) {
    return {
      ...super.toMap(isNested: isNested),
      'type': 'gate',
      'gateType': type.name,
    };
  }
}
