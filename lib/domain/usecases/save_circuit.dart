import 'package:digital_logic_sim_2/domain/entities/circuit.dart';
import 'package:digital_logic_sim_2/domain/repositories/circuit_repository.dart';

class SaveCircuit {
  final CircuitRepository repository;
  SaveCircuit(this.repository);

  Future<void> call(String id, Circuit circuit) async {
    await repository.saveCircuit(id, circuit);
  }
}
