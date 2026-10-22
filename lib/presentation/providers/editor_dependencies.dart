import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_logic_sim_2/domain/services/circuit_simulator.dart';
import 'package:digital_logic_sim_2/domain/usecases/generate_circuit.dart';
import 'package:digital_logic_sim_2/presentation/controllers/custom_component_manager.dart';

// Infrastructure is supplied by the composition root or a test ProviderContainer.
final circuitSimulatorProvider = Provider<CircuitSimulator>(
  (ref) => throw UnimplementedError(
    'Override circuitSimulatorProvider at the app root.',
  ),
);
final customComponentManagerProvider = Provider<CustomComponentManager>(
  (ref) => throw UnimplementedError(
    'Override customComponentManagerProvider at the app root.',
  ),
);
final generateCircuitProvider = Provider<GenerateCircuit>(
  (ref) => throw UnimplementedError(
    'Override generateCircuitProvider at the app root.',
  ),
);
