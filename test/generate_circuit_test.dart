import 'package:flutter_test/flutter_test.dart';
import 'package:digital_logic_sim_2/domain/services/circuit_generator.dart';
import 'package:digital_logic_sim_2/domain/usecases/generate_circuit.dart';
import 'support/fakes.dart';

void main() {
  test('Validates input before contacting the provider', () async {
    final generator = FakeCircuitGenerator();
    final generate = GenerateCircuit(generator);
    await expectLater(
      generate(apiKey: ' ', prompt: 'adder'),
      throwsA(isA<CircuitGenerationException>()),
    );
    await expectLater(
      generate(apiKey: 'key', prompt: ' '),
      throwsA(isA<CircuitGenerationException>()),
    );
    expect(generator.calls, 0);
  });

  test('Returns a parsed circuit and trims request fields', () async {
    final generator = FakeCircuitGenerator();
    final result = await GenerateCircuit(generator)(
      apiKey: ' key ',
      prompt: ' adder ',
    );
    expect(result.definition.name, 'Generated');
    expect(result.json, generator.response);
    expect(generator.lastApiKey, 'key');
    expect(generator.lastPrompt, 'adder');
  });

  for (final response in ['invalid', '[]', '{}', '{"nodes":[],"wires":null}']) {
    test('Rejects malformed circuit response: $response', () async {
      final generator = FakeCircuitGenerator()..response = response;
      await expectLater(
        GenerateCircuit(generator)(apiKey: 'key', prompt: 'adder'),
        throwsA(isA<CircuitGenerationException>()),
      );
    });
  }
}
