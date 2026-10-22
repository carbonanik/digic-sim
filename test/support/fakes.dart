import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';
import 'package:digital_logic_sim_2/domain/repositories/custom_component_repository.dart';
import 'package:digital_logic_sim_2/domain/services/circuit_generator.dart';

class MemoryCustomComponentRepository implements CustomComponentRepository {
  final List<SubCircuitDefinition> definitions = [];

  @override
  Future<List<SubCircuitDefinition>> loadAll() async => List.of(definitions);

  @override
  Future<void> save(SubCircuitDefinition definition) async {
    definitions.removeWhere((item) => item.id == definition.id);
    definitions.add(definition);
  }

  @override
  Future<void> delete(String id) async {
    definitions.removeWhere((item) => item.id == id);
  }
}

class FakeCircuitGenerator implements CircuitGenerator {
  String response = '{"name":"Generated","nodes":[],"wires":[]}';
  int calls = 0;
  String? lastApiKey;
  String? lastPrompt;
  List<SubCircuitDefinition>? lastComponents;
  Future<String> Function()? onGenerate;

  @override
  String buildSystemPrompt({
    List<SubCircuitDefinition> availableComponents = const [],
  }) => 'Test prompt';

  @override
  Future<String> generateCircuit({
    required String apiKey,
    required String prompt,
    List<SubCircuitDefinition> availableComponents = const [],
  }) async {
    calls++;
    lastApiKey = apiKey;
    lastPrompt = prompt;
    lastComponents = availableComponents;
    return onGenerate == null ? response : await onGenerate!();
  }
}
