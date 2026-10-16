import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';

/// Repository interface for persisting custom IC subcircuit definitions.
abstract interface class CustomComponentRepository {
  Future<List<SubCircuitDefinition>> loadAll();
  Future<void> save(SubCircuitDefinition definition);
  Future<void> delete(String id);
}
