import 'package:digital_logic_sim_2/models/circuit_node.dart';
import 'package:digital_logic_sim_2/models/wire.dart';

class CircuitAction {
  final CircuitNode? addedNode;
  final Wire? addedWire;
  final CircuitNode? removedNode;
  final Wire? removedWire;

  CircuitAction({
    this.addedNode,
    this.addedWire,
    this.removedNode,
    this.removedWire,
  });
}
