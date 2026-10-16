import 'package:digital_logic_sim_2/domain/entities/circuit.dart';
import 'package:digital_logic_sim_2/domain/repositories/circuit_repository.dart';

class LoadCircuit {
  final CircuitRepository repository;
  LoadCircuit(this.repository);

  Future<Circuit?> call(String id) async {
    return await repository.loadCircuit(id);
  }
}
