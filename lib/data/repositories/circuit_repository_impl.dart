import 'package:digital_logic_sim_2/data/datasources/local/circuit_storage.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit.dart';
import 'package:digital_logic_sim_2/domain/repositories/circuit_repository.dart';

class CircuitRepositoryImpl implements CircuitRepository {
  final CircuitStorage storage;

  CircuitRepositoryImpl(this.storage);

  @override
  Future<void> saveCircuit(String id, Circuit circuit) async {
    await storage.save(id, circuit);
  }

  @override
  Future<Circuit?> loadCircuit(String id) async {
    return await storage.get(id);
  }
}
