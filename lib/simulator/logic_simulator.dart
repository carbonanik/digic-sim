import '../models/circuit.dart';

class LogicSimulator {
  static void simulate(Circuit circuit) {
    for (int iteration = 0; iteration < circuit.nodes.length + 1; iteration++) {
      bool changed = false;

      // 1. Clear input pin values (or set to default) and 2. Propagate values through wires
      for (final node in circuit.nodes) {
        for (final inputPin in node.inputPins) {
          final oldValue = inputPin.value;

          final wire = circuit.wires.where((w) {
            return w.toNodeId == node.id && w.toPinId == inputPin.id;
          }).firstOrNull;

          if (wire == null) {
            inputPin.value = false;
          } else {
            final fromNode = circuit.nodes
                .where((n) => n.id == wire.fromNodeId)
                .firstOrNull;
            if (fromNode != null) {
              final fromPin = fromNode.outputPins
                  .where((p) => p.id == wire.fromPinId)
                  .firstOrNull;
              inputPin.value = fromPin?.value ?? false;
            }
          }

          if (oldValue != inputPin.value) changed = true;
        }
      }

      // 3. Evaluate each node based on its new inputs
      for (final node in circuit.nodes) {
        final previousOutputs = node.outputPins.map((p) => p.value).toList();

        final inputs = node.inputPins.map((p) => p.value).toList();
        node.evaluate(inputs);

        final currentOutputs = node.outputPins.map((p) => p.value).toList();

        if (!_listsEqual(previousOutputs, currentOutputs)) {
          changed = true;
        }
      }

      if (!changed) break;
    }
  }

  static bool _listsEqual(List<bool> a, List<bool> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
