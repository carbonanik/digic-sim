import '../domain/entities/circuit.dart';
import '../domain/entities/circuit_node.dart';
import '../domain/entities/pin.dart';
import '../domain/entities/wire.dart';

class LogicSimulationResult {
  const LogicSimulationResult({
    required this.elapsed,
    required this.steps,
    required this.stabilized,
  });

  final Duration elapsed;
  final int steps;
  final bool stabilized;
}

class LogicSimulator {
  /// Simulates the circuit until it reaches a stable state or [maxSteps] is reached.
  ///
  /// This implementation improves performance by:
  /// 1. Using lookup maps for O(1) access to nodes and pins.
  /// 2. Using an event-driven approach (dirty-node tracking) to only evaluate
  ///    components that could have changed.
  /// 3. Reducing unnecessary list allocations and iterative searches.
  static LogicSimulationResult simulate(Circuit circuit) {
    final stopwatch = Stopwatch()..start();

    if (circuit.nodes.isEmpty) {
      stopwatch.stop();
      return LogicSimulationResult(
        elapsed: stopwatch.elapsed,
        steps: 0,
        stabilized: true,
      );
    }

    // 1. Setup lookup maps for O(1) complexity.
    final Map<String, CircuitNode> nodeMap = {};
    final Map<String, Pin> outputPinMap = {};
    for (final node in circuit.nodes) {
      nodeMap[node.id] = node;
      for (final pin in node.outputPins) {
        outputPinMap['${node.id}:${pin.id}'] = pin;
      }
    }

    // Map input pins to their source wire
    final Map<String, Wire> wireLookup = {};
    // Map nodes to their outgoing wires for event propagation
    final Map<String, List<Wire>> outgoingWires = {};

    for (final wire in circuit.wires) {
      wireLookup['${wire.toNodeId}:${wire.toPinId}'] = wire;
      outgoingWires.putIfAbsent(wire.fromNodeId, () => []).add(wire);
    }

    // 2. Event-driven simulation
    // Initially, all nodes are considered "dirty" to ensure a full initial state.
    Set<String> dirtyNodeIds = nodeMap.keys.toSet();

    // Safety limit to prevent infinite loops (e.g. unstable oscillators)
    final int maxSteps = circuit.nodes.length + 10;
    int stepCount = 0;

    while (dirtyNodeIds.isNotEmpty && stepCount < maxSteps) {
      stepCount++;

      // Step A: Propagate values to input pins for all currently dirty nodes.
      // We do this in a separate pass to maintain synchronous simulation semantics.
      for (final nodeId in dirtyNodeIds) {
        final node = nodeMap[nodeId];
        if (node == null) continue;

        for (final inputPin in node.inputPins) {
          final wire = wireLookup['${node.id}:${inputPin.id}'];
          if (wire == null) {
            inputPin.value = false;
          } else {
            final fromPin =
                outputPinMap['${wire.fromNodeId}:${wire.fromPinId}'];
            inputPin.value = fromPin?.value ?? false;
          }
        }
      }

      // Step B: Evaluate all dirty nodes and track which nodes need evaluation in the next step.
      final Set<String> nextDirty = {};
      for (final nodeId in dirtyNodeIds) {
        final node = nodeMap[nodeId];
        if (node == null) continue;

        // Capture previous outputs to detect changes
        final outputCount = node.outputPins.length;
        final previousOutputs = List<bool>.generate(
          outputCount,
          (i) => node.outputPins[i].value,
        );

        // Prepare inputs and evaluate
        final inputCount = node.inputPins.length;
        final inputs = List<bool>.generate(
          inputCount,
          (i) => node.inputPins[i].value,
        );
        node.evaluate(inputs);

        // Detect if any output changed
        bool outputsChanged = false;
        for (int i = 0; i < outputCount; i++) {
          if (node.outputPins[i].value != previousOutputs[i]) {
            outputsChanged = true;
            break;
          }
        }

        // If outputs changed, mark all downstream nodes as dirty for the next generation
        if (outputsChanged) {
          final connections = outgoingWires[node.id];
          if (connections != null) {
            for (final wire in connections) {
              nextDirty.add(wire.toNodeId);
            }
          }
        }
      }

      dirtyNodeIds = nextDirty;
    }

    stopwatch.stop();
    return LogicSimulationResult(
      elapsed: stopwatch.elapsed,
      steps: stepCount,
      stabilized: dirtyNodeIds.isEmpty,
    );
  }
}
