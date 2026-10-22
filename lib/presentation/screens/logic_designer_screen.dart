import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_logic_sim_2/presentation/controllers/circuit_controller.dart';
import 'package:digital_logic_sim_2/presentation/providers/editor_dependencies.dart';
import 'package:flutter/services.dart';
import 'package:digital_logic_sim_2/presentation/canvas/circuit_canvas.dart';
import 'package:digital_logic_sim_2/presentation/controllers/workspace_controller.dart';
import 'package:digital_logic_sim_2/presentation/tools/editor_tools.dart';
import 'package:digital_logic_sim_2/presentation/widgets/component_toolbar.dart';
import 'package:digital_logic_sim_2/presentation/widgets/top_bar.dart';
import 'package:digital_logic_sim_2/presentation/widgets/workspace_tabs.dart';

class LogicDesignerScreen extends ConsumerWidget {
  const LogicDesignerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.watch(workspaceControllerProvider);
    final workspaceController = ref.read(workspaceControllerProvider.notifier);
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.delete): () =>
            workspaceController.activeController.deleteSelected(),
        const SingleActivator(LogicalKeyboardKey.backspace): () =>
            workspaceController.activeController.deleteSelected(),
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () =>
            workspaceController.activeController.undo(),
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): () =>
            workspaceController.activeController.redo(),
        const SingleActivator(LogicalKeyboardKey.keyS): () =>
            workspaceController.activeController.selectTool(EditorTool.select),
        const SingleActivator(LogicalKeyboardKey.keyG, control: true): () =>
            workspaceController.activeController.toggleGridSnapping(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Row(
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final id = workspaceState.activeWorkspace.id;
                  ref.watch(circuitControllerProvider(id));
                  return ComponentToolbar(
                    controller: ref.read(
                      circuitControllerProvider(id).notifier,
                    ),
                    workspaceController: workspaceController,
                  );
                },
              ),
              Expanded(
                child: Column(
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        final workspace = workspaceState.activeWorkspace;
                        ref.watch(circuitControllerProvider(workspace.id));
                        return TopBar(
                          controller: ref.read(
                            circuitControllerProvider(workspace.id).notifier,
                          ),
                          workspaceName: workspace.name,
                          generateCircuit: ref.watch(generateCircuitProvider),
                        );
                      },
                    ),
                    WorkspaceTabs(workspaceController: workspaceController),
                    Expanded(
                      child: IndexedStack(
                        index: workspaceState.activeIndex,
                        children: [
                          for (final workspace in workspaceState.workspaces)
                            Consumer(
                              key: ValueKey(workspace.id),
                              builder: (context, ref, _) {
                                ref.watch(
                                  circuitControllerProvider(workspace.id),
                                );
                                return CircuitCanvas(
                                  controller: ref.read(
                                    circuitControllerProvider(
                                      workspace.id,
                                    ).notifier,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
