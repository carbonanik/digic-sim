import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_logic_sim_2/core/di/injection.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/io_nodes.dart';
import 'package:digital_logic_sim_2/presentation/canvas/hit_test.dart';
import 'package:digital_logic_sim_2/presentation/controllers/circuit_controller.dart';
import 'package:digital_logic_sim_2/presentation/controllers/workspace_controller.dart';
import 'package:digital_logic_sim_2/presentation/tools/editor_tools.dart';
import 'package:digital_logic_sim_2/simulation/logic_circuit_simulator.dart';
import 'support/fakes.dart';

ProviderContainer editorContainer() => createTestContainer(
  AppDependencies(
    customComponentRepository: MemoryCustomComponentRepository(),
    simulator: LogicCircuitSimulator(),
    circuitGenerator: FakeCircuitGenerator(),
  ),
);

void main() {
  test('Provider publishes immutable selection, tool, and history state', () {
    final container = editorContainer();
    addTearDown(container.dispose);
    final provider = circuitControllerProvider('editor');
    final controller = container.read(provider.notifier);
    controller.selectTool(EditorTool.input);
    final before = container.read(provider);
    controller.addGateFromTool(const Offset(16, 16));
    controller.selectNode(controller.circuit.nodes.single.id);
    final selected = container.read(provider);
    expect(before.nodeCount, 0);
    expect(before.selectedNodeIds, isEmpty);
    expect(selected.selectedTool, EditorTool.input);
    expect(selected.nodeCount, 1);
    expect(selected.canUndo, isTrue);
    expect(selected.selectedNodeIds, hasLength(1));
    expect(() => selected.selectedNodeIds.clear(), throwsUnsupportedError);
    controller.selectNode(null);
    expect(selected.selectedNodeIds, hasLength(1));
    controller.undo();
    expect(container.read(provider).nodeCount, 0);
    expect(container.read(provider).canRedo, isTrue);
    controller.redo();
    expect(container.read(provider).nodeCount, 1);
    controller.toggleGridSnapping();
    expect(container.read(provider).snapToGridEnabled, isFalse);
  });

  test(
    'Switching tabs retains each document, selection, tool, and history',
    () async {
      final container = editorContainer();
      addTearDown(container.dispose);
      final workspaces = container.read(workspaceControllerProvider.notifier);
      final first = workspaces.activeController;
      first.selectTool(EditorTool.input);
      first.addGateFromTool(const Offset(16, 16));
      first.selectNode(first.circuit.nodes.single.id);
      final firstId = workspaces.activeWorkspace.id;
      workspaces.addWorkspace('Second');
      final second = workspaces.activeController;
      second.selectTool(EditorTool.output);
      second.addGateFromTool(const Offset(320, 16));
      await container.pump();
      workspaces.switchWorkspace(0);
      expect(workspaces.activeController, same(first));
      expect(
        container.read(circuitControllerProvider(firstId)).selectedTool,
        EditorTool.input,
      );
      expect(first.circuit.nodes.single, isA<InputNode>());
      expect(first.selectedNodeIds, hasLength(1));
      first.undo();
      expect(first.circuit.nodes, isEmpty);
      expect(second.circuit.nodes.single, isA<OutputNode>());
      expect(second.canUndo, isTrue);
    },
  );

  test(
    'Closing releases the family provider and rejects stale actions',
    () async {
      final container = editorContainer();
      addTearDown(container.dispose);
      final workspaces = container.read(workspaceControllerProvider.notifier);
      final id = workspaces.activeWorkspace.id;
      final controller = workspaces.activeController;
      controller.selectTool(EditorTool.input);
      controller.addGateFromTool(Offset.zero);
      workspaces.closeWorkspace(0);
      controller.addGateFromTool(const Offset(160, 0));
      controller.updateHoverState(
        position: Offset.zero,
        pinHit: null,
        nodeId: null,
      );
      expect(controller.circuit.nodes, hasLength(1));
      expect(controller.mousePosition, isNull);
      expect(controller.isClosed, isTrue);
      await container.pump();
      expect(container.exists(circuitControllerProvider(id)), isFalse);
      expect(workspaces.activeWorkspace.id, isNot(id));
    },
  );

  test('Wiring updates outputs and undo restores a disconnected circuit', () {
    final container = editorContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      circuitControllerProvider('wiring').notifier,
    );
    controller.selectTool(EditorTool.input);
    controller.addGateFromTool(Offset.zero);
    final input = controller.circuit.nodes.single as InputNode;
    controller.selectTool(EditorTool.output);
    controller.addGateFromTool(const Offset(320, 0));
    final output = controller.circuit.nodes.last as OutputNode;
    controller.startWire(input, input.outputPins.single);
    controller.finishWire(output, output.inputPins.single);
    controller.handleNodeAction(input.id, Offset.zero);
    expect(output.value, isTrue);
    expect(controller.circuit.wires, hasLength(1));
    controller.undo();
    expect(controller.circuit.wires, isEmpty);
    expect(output.value, isFalse);
    controller.redo();
    expect(output.value, isTrue);
  });

  test('Wire drag records the current waypoints for undo and redo', () {
    final container = editorContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      circuitControllerProvider('drag').notifier,
    );
    controller.selectTool(EditorTool.input);
    controller.addGateFromTool(Offset.zero);
    final input = controller.circuit.nodes.single;
    controller.selectTool(EditorTool.output);
    controller.addGateFromTool(const Offset(320, 0));
    final output = controller.circuit.nodes.last;
    controller.startWire(input, input.outputPins.single);
    controller.finishWire(output, output.inputPins.single);
    controller.startWireDrag(
      WireHit(wire: controller.circuit.wires.single, segmentIndex: 0),
      const Offset(160, 32),
    );
    controller.updateWireDrag(const Offset(160, 80));
    final draggedWaypoints = List<Offset>.of(
      controller.circuit.wires.single.waypoints,
    );
    expect(draggedWaypoints, isNotEmpty);
    controller.endWireDrag();
    controller.undo();
    expect(controller.circuit.wires.single.waypoints, isEmpty);
    controller.redo();
    expect(controller.circuit.wires.single.waypoints, draggedWaypoints);
  });

  testWidgets(
    'Hover and simulation repaint without publishing application state',
    (tester) async {
      final container = editorContainer();
      final provider = circuitControllerProvider('runtime');
      final controller = container.read(provider.notifier);
      controller.selectTool(EditorTool.waveform);
      controller.addGateFromTool(Offset.zero);
      var uiUpdates = 0;
      final subscription = container.listen(provider, (_, _) => uiUpdates++);
      final uiState = container.read(provider);
      final circuitRevision = controller.circuitRepaintCounter;
      final overlayRevision = controller.overlayRepaintCounter;
      controller.updateHoverState(
        position: const Offset(16, 16),
        pinHit: null,
        nodeId: null,
      );
      expect(controller.overlayRepaintCounter, greaterThan(overlayRevision));
      expect(controller.circuitRepaintCounter, circuitRevision);
      await tester.pump(const Duration(milliseconds: 60));
      expect(controller.circuitRepaintCounter, greaterThan(circuitRevision));
      expect(uiUpdates, 0);
      expect(container.read(provider), same(uiState));
      subscription.close();
      container.dispose();
      expect(controller.isClosed, isTrue);
      // Container disposal must cancel the waveform timer.
      await tester.pump(const Duration(milliseconds: 60));
    },
  );
}
