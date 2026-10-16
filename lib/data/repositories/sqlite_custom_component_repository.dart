import 'package:digital_logic_sim_2/data/datasources/local/database_helper.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';
import 'package:digital_logic_sim_2/domain/repositories/custom_component_repository.dart';

/// SQLite implementation of CustomComponentRepository.
class SqliteCustomComponentRepository implements CustomComponentRepository {
  @override
  Future<List<SubCircuitDefinition>> loadAll() async {
    return await DatabaseHelper.loadAllICs();
  }

  @override
  Future<void> save(SubCircuitDefinition definition) async {
    await DatabaseHelper.saveIC(definition);
  }

  @override
  Future<void> delete(String id) async {
    await DatabaseHelper.deleteIC(id);
  }
}
