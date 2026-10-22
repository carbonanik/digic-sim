import 'package:digital_logic_sim_2/presentation/controllers/circuit_controller.dart';
import 'package:digital_logic_sim_2/presentation/tools/editor_tools.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_logic_sim_2/presentation/controllers/workspace_controller.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_logic_sim_2/core/di/injection.dart';
import 'package:digital_logic_sim_2/main.dart';
import 'package:digital_logic_sim_2/presentation/canvas/circuit_canvas.dart';
import 'package:digital_logic_sim_2/presentation/widgets/ai_prompt_dialog.dart';
import 'package:digital_logic_sim_2/presentation/screens/logic_designer_screen.dart';
import 'package:digital_logic_sim_2/simulation/logic_circuit_simulator.dart';
import 'support/fakes.dart';

void main() {
  testWidgets('Editor starts with injected dependencies and a workspace', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dependencies = AppDependencies(
      customComponentRepository: MemoryCustomComponentRepository(),
      simulator: LogicCircuitSimulator(),
      circuitGenerator: FakeCircuitGenerator(),
    );
    addTearDown(dependencies.dispose);
    await tester.pumpWidget(LogicDesignerApp(dependencies: dependencies));
    expect(find.byType(CircuitCanvas), findsOneWidget);
    expect(find.text('Main Workspace'), findsWidgets);
  });

  testWidgets('Toolbar and history buttons update the Riverpod editor', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dependencies = AppDependencies(
      customComponentRepository: MemoryCustomComponentRepository(),
      simulator: LogicCircuitSimulator(),
      circuitGenerator: FakeCircuitGenerator(),
    );
    final container = createTestContainer(dependencies);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LogicDesignerScreen()),
      ),
    );
    final workspaces = container.read(workspaceControllerProvider.notifier);
    final provider = circuitControllerProvider(workspaces.activeWorkspace.id);
    await tester.tap(find.text('Input Switch'));
    await tester.pump();
    expect(container.read(provider).selectedTool, EditorTool.input);
    await tester.tapAt(const Offset(600, 400));
    // The canvas waits for the double-tap recognition window before placing.
    await tester.pump(const Duration(milliseconds: 350));
    expect(container.read(provider).nodeCount, 1);
    await tester.tap(find.byTooltip('Undo (Ctrl+Z)'));
    await tester.pump();
    expect(container.read(provider).nodeCount, 0);
    await tester.tap(find.byTooltip('Redo (Ctrl+Shift+Z)'));
    await tester.pump();
    expect(container.read(provider).nodeCount, 1);
    expect(tester.takeException(), isNull);
  });

  for (final closeLastWorkspace in [false, true]) {
    testWidgets(
      'Late pointer events are safe when closing ${closeLastWorkspace ? 'the last' : 'an active'} workspace',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1600, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final dependencies = AppDependencies(
          customComponentRepository: MemoryCustomComponentRepository(),
          simulator: LogicCircuitSimulator(),
          circuitGenerator: FakeCircuitGenerator(),
        );
        addTearDown(dependencies.dispose);
        final container = createTestContainer(dependencies);
        addTearDown(container.dispose);
        final workspaces = container.read(workspaceControllerProvider.notifier);
        if (!closeLastWorkspace) workspaces.addWorkspace('Second');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: LogicDesignerScreen()),
          ),
        );
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: const Offset(600, 400));
        await mouse.moveTo(const Offset(620, 420));
        final closedController = workspaces.activeController;
        expect(closedController.mousePosition, isNotNull);

        workspaces.closeWorkspace(workspaces.activeIndex);
        // The old canvas is still mounted until the next frame. Exercise both
        // hover and exit callbacks while its controller has already been disposed.
        await mouse.moveTo(const Offset(640, 440));
        await mouse.moveTo(const Offset(10, 10));
        await tester.pump();
        await mouse.moveTo(const Offset(600, 400));
        expect(workspaces.activeController, isNot(same(closedController)));
        expect(workspaces.activeController.mousePosition, isNotNull);
        expect(tester.takeException(), isNull);
        await mouse.removePointer();
      },
    );
  }

  testWidgets('Closing AI dialog during generation ignores a late response', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final response = Completer<String>();
    final generator = FakeCircuitGenerator()
      ..onGenerate = () => response.future;
    final dependencies = AppDependencies(
      customComponentRepository: MemoryCustomComponentRepository(),
      simulator: LogicCircuitSimulator(),
      circuitGenerator: generator,
    );
    final container = createTestContainer(dependencies);
    addTearDown(container.dispose);
    final workspaces = container.read(workspaceControllerProvider.notifier);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAiPromptDialog(
                context,
                workspaces.activeController,
                dependencies.generateCircuit,
              ),
              child: const Text('Open AI'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open AI'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField).at(0), 'key');
    await tester.enterText(find.byType(TextField).at(1), 'half adder');
    await tester.tap(find.text('Generate'));
    await tester.pump();
    expect(generator.calls, 1);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    response.complete(generator.response);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
