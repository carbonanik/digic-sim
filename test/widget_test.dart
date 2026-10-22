import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_logic_sim_2/core/di/injection.dart';
import 'package:digital_logic_sim_2/main.dart';
import 'package:digital_logic_sim_2/presentation/canvas/circuit_canvas.dart';
import 'package:digital_logic_sim_2/presentation/widgets/ai_prompt_dialog.dart';
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
    final workspaces = dependencies.createWorkspaceController();
    addTearDown(workspaces.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAiPromptDialog(
                context,
                workspaces.activeController!,
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
