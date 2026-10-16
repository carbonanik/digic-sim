import 'package:digital_logic_sim_2/domain/entities/circuit.dart';

abstract class CircuitRepository {
  Future<void> saveCircuit(String id, Circuit circuit);
  Future<Circuit?> loadCircuit(String id);
}
