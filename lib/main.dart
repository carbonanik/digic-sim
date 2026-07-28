import 'package:digital_logic_sim_2/models/nodes/io_nodes.dart';
import 'package:digital_logic_sim_2/widgets/ai_prompt_dialog.dart';
import 'package:digital_logic_sim_2/widgets/component_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'controllers/circuit_controller.dart';
import 'controllers/workspace_controller.dart';
import 'editor/circuit_canvas.dart';
import 'editor/editor_tools.dart';
import 'utils/preset_library.dart';
import 'widgets/workspace_tabs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PresetLibrary.initialize();
  await CircuitController.initializeCustomDefinitions();
  runApp(const LogicDesignerApp());
}

class LogicDesignerApp extends StatelessWidget {
  const LogicDesignerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logic Designer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff0f172a),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff38bdf8),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LogicDesignerScreen(),
    );
  }
}

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
        // shortcut for snap
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
                          builder: (context, _) => _TopBar(
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

class _TopBar extends StatelessWidget {
  final CircuitController controller;
  final String workspaceName;

  const _TopBar({required this.controller, required this.workspaceName});

  @override
  Widget build(BuildContext context) {
    final hasSelection =
        controller.selectedNodeIds.isNotEmpty ||
        controller.selectedWireId != null;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xff0b1120),
        border: const Border(bottom: BorderSide(color: Color(0xff1f2937))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Project Status / Title
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LOGIC LAB WORKSPACE',
                style: TextStyle(
                  color: Color(0xff4b5563),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                workspaceName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),

          // History Group
          _TopBarGroup(
            children: [
              _IconButton(
                icon: Icons.undo_rounded,
                tooltip: 'Undo (Ctrl+Z)',
                onTap: controller.undo,
              ),
              _IconButton(
                icon: Icons.redo_rounded,
                tooltip: 'Redo (Ctrl+Shift+Z)',
                onTap: controller.redo,
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Tool Indicator
          _ActiveToolPill(tool: controller.selectedTool),

          if (hasSelection) ...[
            const SizedBox(width: 16),
            _TopBarGroup(
              children: [
                _IconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete Selected',
                  onTap: controller.deleteSelected,
                  color: Colors.redAccent.withOpacity(0.1),
                  iconColor: Colors.redAccent.shade100,
                ),
              ],
            ),
          ],

          const Spacer(),

          // Canvas Controls
          _TopBarGroup(
            children: [
              _ToggleAction(
                icon: controller.snapToGridEnabled
                    ? Icons.grid_on_rounded
                    : Icons.grid_off_rounded,
                label: 'Snap',
                active: controller.snapToGridEnabled,
                onTap: controller.toggleGridSnapping,
              ),
            ],
          ),
          const SizedBox(width: 12),

          // AI Generate Action
          _AiButton(onTap: () => showAiPromptDialog(context, controller)),
          const SizedBox(width: 12),

          // IC Action
          _TopBarButton(
            icon: Icons.auto_awesome_mosaic_outlined,
            label: 'Create IC',
            onTap: () => _showSaveDialog(context),
            color: const Color(0xff38bdf8),
            textColor: const Color(0xff020617),
          ),
          const SizedBox(width: 12),

          // Clear Action
          _TopBarButton(
            icon: Icons.layers_clear_outlined,
            label: 'Clear',
            onTap: () => _confirmClear(context),
            color: Colors.transparent,
            textColor: Colors.redAccent.shade100,
            borderColor: Colors.redAccent.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff0b1120),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xff1f2937)),
        ),
        title: const Text('Clear Workspace?'),
        content: const Text(
          'This will delete all components and wires. This action is permanent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    final inputNodes = controller.circuit.nodes.whereType<InputNode>().toList();
    final outputNodes = controller.circuit.nodes
        .whereType<OutputNode>()
        .toList();

    final nameController = TextEditingController();
    final inputControllers = List.generate(
      inputNodes.length,
      (i) => TextEditingController(text: inputNodes[i].label),
    );
    final outputControllers = List.generate(
      outputNodes.length,
      (i) => TextEditingController(text: outputNodes[i].label),
    );

    Color selectedColor = const Color(0xff1e3a8a);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xff0f172a),
          title: const Text('IC Designer'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('COMPONENT NAME', style: _headerStyle),
                  TextField(
                    controller: nameController,
                    decoration: _inputDeco('e.g. Full Adder'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  const Text('BODY COLOR', style: _headerStyle),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        [
                              const Color(0xff1e3a8a),
                              const Color(0xff581c87),
                              const Color(0xff701a75),
                              const Color(0xff14532d),
                              const Color(0xff7c2d12),
                              const Color(0xff0f172a),
                            ]
                            .map(
                              (color) => GestureDetector(
                                onTap: () =>
                                    setState(() => selectedColor = color),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedColor == color
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 20),
                  if (inputNodes.isNotEmpty) ...[
                    const Text('INPUT LABELS', style: _headerStyle),
                    const SizedBox(height: 8),
                    ...List.generate(
                      inputNodes.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TextField(
                          controller: inputControllers[i],
                          decoration: _inputDeco('Input ${i + 1} Label'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (outputNodes.isNotEmpty) ...[
                    const Text('OUTPUT LABELS', style: _headerStyle),
                    const SizedBox(height: 8),
                    ...List.generate(
                      outputNodes.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TextField(
                          controller: outputControllers[i],
                          decoration: _inputDeco('Output ${i + 1} Label'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  controller.saveCurrentAsComponent(
                    name: nameController.text,
                    color: selectedColor,
                    inputLabels: inputControllers.map((c) => c.text).toList(),
                    outputLabels: outputControllers.map((c) => c.text).toList(),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create IC'),
            ),
          ],
        ),
      ),
    );
  }

  static const _headerStyle = TextStyle(
    color: Color(0xff94a3b8),
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xff1e293b),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  );
}

class _TopBarGroup extends StatelessWidget {
  final List<Widget> children;
  const _TopBarGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xff1e293b).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xff1f2937)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  final Color? iconColor;

  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color ?? Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor ?? const Color(0xff94a3b8),
          ),
        ),
      ),
    );
  }
}

class _ActiveToolPill extends StatelessWidget {
  final EditorTool tool;
  const _ActiveToolPill({required this.tool});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xff38bdf8).withOpacity(0.1),
            const Color(0xff38bdf8).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xff38bdf8).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xff38bdf8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            tool.name.toUpperCase(),
            style: const TextStyle(
              color: Color(0xff38bdf8),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleAction({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xff38bdf8).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? const Color(0xff38bdf8) : const Color(0xff94a3b8),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xff94a3b8),
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color? textColor;
  final Color? borderColor;

  const _TopBarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: textColor ?? Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AiButton({required this.onTap});

  @override
  State<_AiButton> createState() => _AiButtonState();
}

class _AiButtonState extends State<_AiButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _pulse;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glow = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _glow,
          builder: (context, _) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff7c3aed), Color(0xff0891b2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xff8b5cf6,
                    ).withOpacity(_hovered ? 0.6 : _glow.value * 0.5),
                    blurRadius: _hovered ? 18 : 10,
                    spreadRadius: _hovered ? 2 : 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: _hovered ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI Generate',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
