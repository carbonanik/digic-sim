import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';
import 'package:digital_logic_sim_2/domain/repositories/custom_component_repository.dart';
import 'package:digital_logic_sim_2/domain/services/circuit_simulator.dart';
import 'package:digital_logic_sim_2/presentation/controllers/circuit_simulation_service.dart';
import 'package:digital_logic_sim_2/presentation/controllers/custom_component_manager.dart';
import 'package:digital_logic_sim_2/domain/services/logic_engine.dart';

class MockCustomComponentRepository implements CustomComponentRepository {
  final List<SubCircuitDefinition> definitions = [];

  @override
  Future<List<SubCircuitDefinition>> loadAll() async => definitions;

  @override
  Future<void> save(SubCircuitDefinition definition) async {
    definitions.add(definition);
  }

  @override
  Future<void> delete(String id) async {
    definitions.removeWhere((d) => d.id == id);
  }
}

class MockCircuitSimulator implements CircuitSimulator {
  int simulateCallCount = 0;

  @override
  LogicSimulationResult simulate(Circuit circuit) {
    simulateCallCount++;
    return const LogicSimulationResult(
      elapsed: Duration(microseconds: 100),
      steps: 1,
      stabilized: true,
    );
  }
}

void main() {
  group('Repository and Simulator Abstractions Tests', () {
    test('CustomComponentManager uses CustomComponentRepository abstraction', () async {
      final mockRepo = MockCustomComponentRepository();
      final manager = CustomComponentManager(repository: mockRepo);

      final def = SubCircuitDefinition(
        id: 'test_ic',
        name: 'Test IC',
        nodes: [],
        wires: [],
        color: const Color(0xFF000000),
        inputLabels: [],
        outputLabels: [],
      );

      manager.saveCustomDefinition(def);

      expect(mockRepo.definitions.length, 1);
      expect(mockRepo.definitions.first.id, 'test_ic');

      manager.removeCustomDefinition(def);
      expect(mockRepo.definitions, isEmpty);
    });

    test('CircuitSimulationService uses CircuitSimulator abstraction', () {
      final mockSimulator = MockCircuitSimulator();
      final service = CircuitSimulationService(simulator: mockSimulator);

      final circuit = Circuit(nodes: [], wires: []);
      service.simulate(circuit);

      expect(mockSimulator.simulateCallCount, 1);
      expect(service.lastSimulationSteps, 1);
      expect(service.lastSimulationStabilized, isTrue);
    });
  });
}
