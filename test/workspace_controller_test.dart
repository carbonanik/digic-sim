import 'package:digital_logic_sim_2/presentation/controllers/workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_logic_sim_2/core/di/injection.dart';
import 'package:digital_logic_sim_2/simulation/logic_circuit_simulator.dart';
import 'support/fakes.dart';

void main() {
  AppDependencies dependencies() => AppDependencies(
    customComponentRepository: MemoryCustomComponentRepository(),
    simulator: LogicCircuitSimulator(),
    circuitGenerator: FakeCircuitGenerator(),
  );

  test('Closing a preceding tab preserves the active workspace', () {
    final container = createTestContainer(dependencies());
    addTearDown(container.dispose);
    final workspaces = container.read(workspaceControllerProvider.notifier);
    workspaces.addWorkspace('Second');
    workspaces.addWorkspace('Third');
    final active = workspaces.activeWorkspace;
    workspaces.closeWorkspace(0);
    expect(workspaces.activeWorkspace, same(active));
    expect(workspaces.activeIndex, 1);
    expect(workspaces.workspaces.map((item) => item.id).toSet(), hasLength(2));
    expect(() => workspaces.workspaces.clear(), throwsUnsupportedError);
  });

  test('Closing the last workspace creates a fresh usable controller', () {
    final container = createTestContainer(dependencies());
    addTearDown(container.dispose);
    final workspaces = container.read(workspaceControllerProvider.notifier);
    final oldController = workspaces.activeController;
    workspaces.closeWorkspace(0);
    expect(workspaces.workspaces, hasLength(1));
    expect(workspaces.activeController, isNot(same(oldController)));
    expect(workspaces.activeWorkspace.name, 'Main Workspace');
  });

  test(
    'Custom components are shared within an app and isolated between apps',
    () async {
      final first = dependencies();
      final second = dependencies();
      final container = createTestContainer(first);
      addTearDown(container.dispose);
      final workspaces = container.read(workspaceControllerProvider.notifier);
      workspaces.activeController.importIC(
        '{"id":"shared","name":"Shared","nodes":[],"wires":[]}',
      );
      workspaces.addWorkspace('Second');
      expect(workspaces.activeController.customDefinitions.single.id, 'shared');
      expect(second.customComponents.customDefinitions, isEmpty);
      expect(
        () => first.customComponents.customDefinitions.clear(),
        throwsUnsupportedError,
      );
    },
  );
}
