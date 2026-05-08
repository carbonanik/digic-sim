import '../models/circuit.dart';
import '../models/gate_type.dart';

class LogicSimulator {
  static void simulate(Circuit circuit) {
    final values = {for (final node in circuit.nodes) node.id: node.value};

    for (int iteration = 0; iteration < circuit.nodes.length + 1; iteration++) {
      bool changed = false;

      for (final node in circuit.nodes) {
        final inputs = <bool>[];

        for (final inputPin in node.inputPins) {
          final wire = circuit.wires.where((w) {
            return w.toNodeId == node.id && w.toPinId == inputPin.id;
          }).firstOrNull;

          if (wire == null) {
            inputs.add(false);
          } else {
            inputs.add(values[wire.fromNodeId] ?? false);
          }
        }

        final newValue = _evaluateGate(node.type, inputs, node.value);

        if (values[node.id] != newValue) {
          values[node.id] = newValue;
          changed = true;
        }
      }

      if (!changed) break;
    }

    for (final node in circuit.nodes) {
      node.value = values[node.id] ?? false;
    }
  }

  static bool _evaluateGate(
    GateType type,
    List<bool> inputs,
    bool currentValue,
  ) {
    switch (type) {
      case GateType.input:
        return currentValue;

      case GateType.output:
        return inputs.isNotEmpty ? inputs.first : false;

      case GateType.and:
        return inputs.length >= 2 && inputs.every((value) => value);

      case GateType.or:
        return inputs.any((value) => value);

      case GateType.not:
        return inputs.isNotEmpty ? !inputs.first : true;

      case GateType.nand:
        return !(inputs.length >= 2 && inputs.every((value) => value));

      case GateType.nor:
        return !inputs.any((value) => value);

      case GateType.xor:
        return inputs.where((value) => value).length.isOdd;
    }
  }
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }

    return null;
  }
}
