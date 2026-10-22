import 'dart:convert';
import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';
import 'package:digital_logic_sim_2/domain/services/circuit_generator.dart';

class GeneratedCircuit {
  final String json;
  final SubCircuitDefinition definition;

  const GeneratedCircuit({required this.json, required this.definition});
}

/// Validates the request and parses provider output before it reaches the editor.
class GenerateCircuit {
  final CircuitGenerator _generator;

  const GenerateCircuit(this._generator);

  String buildSystemPrompt({
    List<SubCircuitDefinition> availableComponents = const [],
  }) => _generator.buildSystemPrompt(availableComponents: availableComponents);

  Future<GeneratedCircuit> call({
    required String apiKey,
    required String prompt,
    List<SubCircuitDefinition> availableComponents = const [],
  }) async {
    if (apiKey.trim().isEmpty) {
      throw const CircuitGenerationException(
        'Please enter your Gemini API key.',
      );
    }
    if (prompt.trim().isEmpty) {
      throw const CircuitGenerationException(
        'Please describe the circuit you want to generate.',
      );
    }
    final json = await _generator.generateCircuit(
      apiKey: apiKey.trim(),
      prompt: prompt.trim(),
      availableComponents: availableComponents,
    );
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      if (map['nodes'] is! List || map['wires'] is! List) {
        throw const FormatException('A circuit must contain nodes and wires.');
      }
      return GeneratedCircuit(
        json: json,
        definition: SubCircuitDefinition.fromMap(map),
      );
    } catch (error) {
      throw CircuitGenerationException('Failed to parse circuit: $error');
    }
  }
}
