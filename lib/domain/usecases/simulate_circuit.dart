import 'package:digital_logic_sim_2/domain/entities/circuit.dart';
import 'package:digital_logic_sim_2/domain/services/circuit_simulator.dart';
import 'package:digital_logic_sim_2/domain/services/logic_engine.dart';

class SimulateCircuit {
  final CircuitSimulator _simulator;

  SimulateCircuit(this._simulator);

  LogicSimulationResult call(Circuit circuit) => _simulator.simulate(circuit);
}
