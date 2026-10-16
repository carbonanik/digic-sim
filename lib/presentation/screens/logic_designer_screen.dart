import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:digital_logic_sim_2/presentation/canvas/circuit_canvas.dart';
import 'package:digital_logic_sim_2/presentation/controllers/workspace_controller.dart';
import 'package:digital_logic_sim_2/presentation/tools/editor_tools.dart';
import 'package:digital_logic_sim_2/presentation/widgets/component_toolbar.dart';
import 'package:digital_logic_sim_2/presentation/widgets/top_bar.dart';
import 'package:digital_logic_sim_2/presentation/widgets/workspace_tabs.dart';

class LogicDesignerScreen extends StatefulWidget {
  const LogicDesignerScreen({super.key});

  @override
  State<LogicDesignerScreen> createState() => _LogicDesignerScreenState();
}

class _LogicDesignerScreenState extends State<LogicDesignerScreen> {
  final WorkspaceController workspaceController = WorkspaceController();

  @override
  void dispose() {
    workspaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.delete): () =>
            workspaceController.activeController?.deleteSelected(),
        const SingleActivator(LogicalKeyboardKey.backspace): () =>
            workspaceController.activeController?.deleteSelected(),
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () =>
            workspaceController.activeController?.undo(),
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): () =>
            workspaceController.activeController?.redo(),
        const SingleActivator(LogicalKeyboardKey.keyS): () =>
            workspaceController.activeController?.selectTool(EditorTool.select),
        const SingleActivator(LogicalKeyboardKey.keyG, control: true): () =>
            workspaceController.activeController?.toggleGridSnapping(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Row(
            children: [
              // 1. Toolbar: Listens to workspace changes to swap the controller it displays
              ListenableBuilder(
                listenable: workspaceController,
                builder: (context, _) {
                  final controller = workspaceController.activeController!;
                  return AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) => ComponentToolbar(
                      controller: controller,
                      workspaceController: workspaceController,
                    ),
                  );
                },
              ),
              Expanded(
                child: Column(
                  children: [
                    // 2. Top Bar: Listens to workspace changes for title/active controller
                    ListenableBuilder(
                      listenable: workspaceController,
                      builder: (context, _) {
                        final activeWorkspace =
                            workspaceController.activeWorkspace!;
                        final controller = activeWorkspace.controller;
                        return AnimatedBuilder(
                          animation: controller,
                          builder: (context, _) => TopBar(
                            controller: controller,
                            workspaceName: activeWorkspace.name,
                          ),
                        );
                      },
                    ),
                    // 3. Tabs: Listens to workspace controller
                    ListenableBuilder(
                      listenable: workspaceController,
                      builder: (context, _) => WorkspaceTabs(
                        workspaceController: workspaceController,
                      ),
                    ),
                    // 4. Canvas Stack: Uses IndexedStack and only rebuilds when workspaces are added/removed
                    Expanded(
                      child: ListenableBuilder(
                        listenable: workspaceController,
                        builder: (context, _) {
                          return IndexedStack(
                            index: workspaceController.activeIndex,
                            children: workspaceController.workspaces.map((w) {
                              return CircuitCanvas(
                                key: ValueKey(w.id),
                                controller: w.controller,
                              );
                            }).toList(),
                          );
                        },
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
