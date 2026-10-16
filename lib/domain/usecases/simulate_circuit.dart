import 'package:digital_logic_sim_2/domain/entities/circuit.dart';
import 'package:digital_logic_sim_2/simulation/engine/logic_engine.dart';

class SimulateCircuit {
  LogicSimulationResult call(Circuit circuit) {
    return LogicSimulator.simulate(circuit);
  }
}
