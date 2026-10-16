import 'package:flutter_test/flutter_test.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/gate_node.dart';
import 'package:digital_logic_sim_2/domain/entities/pin.dart';
import 'package:digital_logic_sim_2/domain/entities/wire.dart';
import 'package:digital_logic_sim_2/presentation/controllers/commands/circuit_command.dart';
import 'package:digital_logic_sim_2/presentation/controllers/commands/command_history.dart';

void main() {
  group('CommandHistory and CircuitCommand tests', () {
    late Circuit circuit;
    late CommandHistory history;

    setUp(() {
      circuit = Circuit(nodes: [], wires: []);
      history = CommandHistory();
    });

    test('AddNodesCommand adds and removes node correctly', () {
      final node = GateNode(
        id: 'gate_1',
        position: const Offset(10, 20),
        type: Gate.and,
        inputPins: [
          Pin(id: 'in_0', nodeId: 'gate_1', isInput: true, localPosition: Offset.zero),
        ],
        outputPins: [
          Pin(id: 'out_0', nodeId: 'gate_1', isInput: false, localPosition: Offset.zero),
        ],
      );

      final command = AddNodesCommand([node]);
      history.execute(command, circuit);

      expect(circuit.nodes.length, 1);
      expect(circuit.nodes.first.id, 'gate_1');
      expect(history.canUndo, isTrue);

      history.undo(circuit);

      expect(circuit.nodes, isEmpty);
      expect(history.canRedo, isTrue);

      history.redo(circuit);

      expect(circuit.nodes.length, 1);
    });

    test('RemoveNodesAndWiresCommand executes and undoes correctly', () {
      final node = GateNode(
        id: 'gate_1',
        position: const Offset(10, 20),
        type: Gate.and,
        inputPins: [
          Pin(id: 'in_0', nodeId: 'gate_1', isInput: true, localPosition: Offset.zero),
        ],
        outputPins: [
          Pin(id: 'out_0', nodeId: 'gate_1', isInput: false, localPosition: Offset.zero),
        ],
      );
      final wire = Wire(
        id: 'wire_1',
        fromNodeId: 'gate_1',
        fromPinId: 'out_0',
        toNodeId: 'gate_2',
        toPinId: 'in_0',
      );

      circuit.nodes.add(node);
      circuit.wires.add(wire);

      final command = RemoveNodesAndWiresCommand(
        nodes: [node],
        wires: [wire],
      );

      history.execute(command, circuit);

      expect(circuit.nodes, isEmpty);
      expect(circuit.wires, isEmpty);

      history.undo(circuit);

      expect(circuit.nodes.length, 1);
      expect(circuit.wires.length, 1);
    });
  });
}
