import 'package:digital_logic_sim_2/domain/entities/circuit.dart';
import 'package:digital_logic_sim_2/simulation/engine/logic_engine.dart';

/// Interface for executing digital logic circuit simulation.
abstract interface class CircuitSimulator {
  LogicSimulationResult simulate(Circuit circuit);
}
