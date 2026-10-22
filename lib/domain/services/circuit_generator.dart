import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';

/// Port for generating a circuit using an external provider.
abstract interface class CircuitGenerator {
  String buildSystemPrompt({
    List<SubCircuitDefinition> availableComponents = const [],
  });

  Future<String> generateCircuit({
    required String apiKey,
    required String prompt,
    List<SubCircuitDefinition> availableComponents = const [],
  });
}

class CircuitGenerationException implements Exception {
  final String message;
  const CircuitGenerationException(this.message);

  @override
  String toString() => message;
}
