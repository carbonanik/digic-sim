import 'circuit_node.dart';
import 'wire.dart';

class Circuit {
  final List<CircuitNode> nodes;
  final List<Wire> wires;

  Circuit({required this.nodes, required this.wires});
}
