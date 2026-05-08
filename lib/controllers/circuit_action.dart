import 'package:digital_logic_sim_2/models/circuit_node.dart';
import 'package:digital_logic_sim_2/models/wire.dart';

class CircuitAction {
  final List<CircuitNode> addedNodes;
  final List<Wire> addedWires;
  final List<CircuitNode> removedNodes;
  final List<Wire> removedWires;

  CircuitAction({
    this.addedNodes = const [],
    this.addedWires = const [],
    this.removedNodes = const [],
    this.removedWires = const [],
  });
}
