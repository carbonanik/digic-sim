import 'package:digital_logic_sim_2/domain/entities/circuit.dart';
import 'package:digital_logic_sim_2/domain/services/circuit_simulator.dart';
import 'package:digital_logic_sim_2/simulation/engine/logic_engine.dart';

/// Default implementation of CircuitSimulator delegating to LogicSimulator engine.
class LogicCircuitSimulator implements CircuitSimulator {
  @override
  LogicSimulationResult simulate(Circuit circuit) {
    return LogicSimulator.simulate(circuit);
  }
}
