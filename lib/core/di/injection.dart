import 'package:http/http.dart' as http;
import 'package:digital_logic_sim_2/data/datasources/remote/gemini_api.dart';
import 'package:digital_logic_sim_2/data/repositories/sqlite_custom_component_repository.dart';
import 'package:digital_logic_sim_2/domain/repositories/custom_component_repository.dart';
import 'package:digital_logic_sim_2/domain/services/circuit_generator.dart';
import 'package:digital_logic_sim_2/domain/services/circuit_simulator.dart';
import 'package:digital_logic_sim_2/domain/usecases/generate_circuit.dart';
import 'package:digital_logic_sim_2/presentation/controllers/circuit_controller.dart';
import 'package:digital_logic_sim_2/presentation/controllers/circuit_simulation_service.dart';
import 'package:digital_logic_sim_2/presentation/controllers/create_node_factory.dart';
import 'package:digital_logic_sim_2/presentation/controllers/custom_component_manager.dart';
import 'package:digital_logic_sim_2/presentation/controllers/grid.dart';
import 'package:digital_logic_sim_2/presentation/controllers/workspace_controller.dart';
import 'package:digital_logic_sim_2/simulation/logic_circuit_simulator.dart';

/// Composition root: concrete infrastructure is selected only here.
class AppDependencies {
  final CustomComponentManager customComponents;
  final CircuitSimulator simulator;
  final GenerateCircuit generateCircuit;
  final http.Client? _ownedHttpClient;

  AppDependencies({
    required CustomComponentRepository customComponentRepository,
    required this.simulator,
    required CircuitGenerator circuitGenerator,
  }) : customComponents = CustomComponentManager(
         repository: customComponentRepository,
       ),
       generateCircuit = GenerateCircuit(circuitGenerator),
       _ownedHttpClient = null;

  AppDependencies._production(http.Client client)
    : customComponents = CustomComponentManager(
        repository: SqliteCustomComponentRepository(),
      ),
      simulator = LogicCircuitSimulator(),
      generateCircuit = GenerateCircuit(GeminiService(client: client)),
      _ownedHttpClient = client;

  factory AppDependencies.production() =>
      AppDependencies._production(http.Client());

  Future<void> initialize() => customComponents.initialize();

  WorkspaceController createWorkspaceController() => WorkspaceController(
    createCircuitController: () => CircuitController(
      createNodeFactory: CreateNodeFactory(),
      grid: Grid(),
      simulationService: CircuitSimulationService(simulator: simulator),
      customComponentManager: customComponents,
    ),
  );

  void dispose() => _ownedHttpClient?.close();
}
