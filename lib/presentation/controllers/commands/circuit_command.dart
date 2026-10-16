import 'dart:ui';
import 'package:digital_logic_sim_2/domain/entities/circuit.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit_node.dart';
import 'package:digital_logic_sim_2/domain/entities/wire.dart';

/// Base interface for all circuit modification commands.
abstract interface class CircuitCommand {
  void execute(Circuit circuit);
  void undo(Circuit circuit);
}

/// Command to add nodes to the circuit.
class AddNodesCommand implements CircuitCommand {
  final List<CircuitNode> nodes;

  AddNodesCommand(this.nodes);

  @override
  void execute(Circuit circuit) {
    circuit.nodes.addAll(nodes);
  }

  @override
  void undo(Circuit circuit) {
    for (final node in nodes) {
      circuit.nodes.removeWhere((n) => n.id == node.id);
    }
  }
}

/// Command to remove specified nodes and/or connected wires from the circuit.
class RemoveNodesAndWiresCommand implements CircuitCommand {
  final List<CircuitNode> nodes;
  final List<Wire> wires;

  RemoveNodesAndWiresCommand({
    this.nodes = const [],
    this.wires = const [],
  });

  @override
  void execute(Circuit circuit) {
    for (final node in nodes) {
      circuit.nodes.removeWhere((n) => n.id == node.id);
    }
    for (final wire in wires) {
      circuit.wires.removeWhere((w) => w.id == wire.id);
    }
  }

  @override
  void undo(Circuit circuit) {
    circuit.nodes.addAll(nodes);
    circuit.wires.addAll(wires);
  }
}

/// Command to add wires to the circuit.
class AddWiresCommand implements CircuitCommand {
  final List<Wire> wires;

  AddWiresCommand(this.wires);

  @override
  void execute(Circuit circuit) {
    circuit.wires.addAll(wires);
  }

  @override
  void undo(Circuit circuit) {
    for (final wire in wires) {
      circuit.wires.removeWhere((w) => w.id == wire.id);
    }
  }
}

/// Command to remove a single wire from the circuit.
class RemoveWireCommand implements CircuitCommand {
  final Wire wire;

  RemoveWireCommand(this.wire);

  @override
  void execute(Circuit circuit) {
    circuit.wires.removeWhere((w) => w.id == wire.id);
  }

  @override
  void undo(Circuit circuit) {
    circuit.wires.add(wire);
  }
}

/// Command for updated wire waypoints (e.g. after wire drag).
class UpdateWireWaypointsCommand implements CircuitCommand {
  final String wireId;
  final List<Offset> oldWaypoints;
  final List<Offset> newWaypoints;

  UpdateWireWaypointsCommand({
    required this.wireId,
    required this.oldWaypoints,
    required this.newWaypoints,
  });

  @override
  void execute(Circuit circuit) {
    final idx = circuit.wires.indexWhere((w) => w.id == wireId);
    if (idx != -1) {
      circuit.wires[idx] = circuit.wires[idx].copyWith(waypoints: newWaypoints);
    }
  }

  @override
  void undo(Circuit circuit) {
    final idx = circuit.wires.indexWhere((w) => w.id == wireId);
    if (idx != -1) {
      circuit.wires[idx] = circuit.wires[idx].copyWith(waypoints: oldWaypoints);
    }
  }
}

/// Empty/No-op command placeholder for completed UI operations.
class CustomCircuitCommand implements CircuitCommand {
  final void Function(Circuit circuit) onExecute;
  final void Function(Circuit circuit) onUndo;

  CustomCircuitCommand({
    required this.onExecute,
    required this.onUndo,
  });

  @override
  void execute(Circuit circuit) => onExecute(circuit);

  @override
  void undo(Circuit circuit) => onUndo(circuit);
}
