import 'package:flutter_test/flutter_test.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit.dart';
import 'package:digital_logic_sim_2/domain/services/circuit_simulator.dart';
import 'package:digital_logic_sim_2/domain/services/logic_engine.dart';
import 'package:digital_logic_sim_2/presentation/controllers/circuit_simulation_service.dart';
import 'package:digital_logic_sim_2/presentation/controllers/create_node_factory.dart';
import 'package:digital_logic_sim_2/presentation/tools/editor_tools.dart';

class RecordingSimulator implements CircuitSimulator {
  final List<Circuit> circuits = [];
  @override
  LogicSimulationResult simulate(Circuit circuit) {
    circuits.add(circuit);
    return const LogicSimulationResult(
      elapsed: Duration.zero,
      steps: 1,
      stabilized: true,
    );
  }
}

void main() {
  testWidgets(
    'Timer follows the current circuit and stops for an empty circuit',
    (tester) async {
      final simulator = RecordingSimulator();
      final service = CircuitSimulationService(simulator: simulator);
      addTearDown(service.dispose);
      Circuit waveformCircuit() => Circuit(
        nodes: [CreateNodeFactory().create(EditorTool.waveform, Offset.zero)],
        wires: [],
      );
      final original = waveformCircuit();
      final replacement = waveformCircuit();
      service.updateClockTimer(circuit: original, onTick: () {});
      await tester.pump(const Duration(milliseconds: 20));
      expect(simulator.circuits.last, same(original));
      service.updateClockTimer(circuit: replacement, onTick: () {});
      await tester.pump(const Duration(milliseconds: 20));
      expect(simulator.circuits.last, same(replacement));
      final calls = simulator.circuits.length;
      service.updateClockTimer(
        circuit: Circuit(nodes: [], wires: []),
        onTick: () {},
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(simulator.circuits.length, calls);
    },
  );
}
