import 'package:digital_logic_sim_2/domain/entities/nodes/io_nodes.dart';
import 'package:digital_logic_sim_2/models/pin_layout.dart';
import 'package:digital_logic_sim_2/widgets/ai_prompt_dialog.dart';
import 'package:digital_logic_sim_2/widgets/component_toolbar.dart';
import 'package:digital_logic_sim_2/widgets/ic_pin_layout_designer.dart';
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
    Map<String, PinPlacement> pinPlacements = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
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
                    OutlinedButton.icon(
                      icon: const Icon(
                        Icons.dashboard_customize_rounded,
                        size: 16,
                      ),
                      label: const Text('Arrange Pins'),
                      onPressed: () async {
                        final pins = [
                          for (int i = 0; i < inputNodes.length; i++)
                            PinInfo(
                              key: inputNodes[i].id,
                              label: inputControllers[i].text,
                              isInput: true,
                            ),
                          for (int i = 0; i < outputNodes.length; i++)
                            PinInfo(
                              key: outputNodes[i].id,
                              label: outputControllers[i].text,
                              isInput: false,
                            ),
                        ];
                        final result = await IcPinLayoutDesigner.show(
                          context,
                          icName: nameController.text.isEmpty
                              ? 'IC'
                              : nameController.text,
                          icColor: selectedColor,
                          pins: pins,
                          initialPlacements:
                              pinPlacements, // preserves edits if reopened
                        );
                        if (result != null) {
                          setState(() => pinPlacements = result);
                        }
                      },
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
              // ElevatedButton(
              //   onPressed: () async {
              //     final pins = [
              //       for (int i = 0; i < inputNodes.length; i++)
              //         PinInfo(
              //           key: inputNodes[i].id,
              //           label: inputControllers[i].text,
              //           isInput: true,
              //         ),
              //       for (int i = 0; i < outputNodes.length; i++)
              //         PinInfo(
              //           key: outputNodes[i].id,
              //           label: outputControllers[i].text,
              //           isInput: false,
              //         ),
              //     ];
              //     final placements = await IcPinLayoutDesigner.show(
              //       context,
              //       icName: nameController.text,
              //       icColor: selectedColor,
              //       pins: pins,
              //       initialPlacements: {},
              //     );
              //   },
              //   child: const Text('Pin Layout'),
              // ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    controller.saveCurrentAsComponent(
                      name: nameController.text,
                      color: selectedColor,
                      inputLabels: inputControllers.map((c) => c.text).toList(),
                      outputLabels: outputControllers
                          .map((c) => c.text)
                          .toList(),
                      pinPlacements: pinPlacements,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Create IC'),
              ),
            ],
          );
        },
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

var j = {
  "id": "8-bit_adder",
  "name": "8-Bit Adder",
  "nodes": [
    {
      "id": "[#ab871]",
      "position": {"dx": 288.0, "dy": 192.0},
      "inputPins": [
        {
          "id": "in_0",
          "nodeId": "[#ab871]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "in_1",
          "nodeId": "[#ab871]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 48.0},
          "value": false,
        },
        {
          "id": "in_2",
          "nodeId": "[#ab871]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 64.0},
          "value": false,
        },
      ],
      "outputPins": [
        {
          "id": "out_0",
          "nodeId": "[#ab871]",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "out_1",
          "nodeId": "[#ab871]",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 48.0},
          "value": false,
        },
      ],
      "type": "composed",
      "reference": "full_adder",
    },
    {
      "id": "[#fbbeb]",
      "position": {"dx": 288.0, "dy": 320.0},
      "inputPins": [
        {
          "id": "in_0",
          "nodeId": "[#fbbeb]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "in_1",
          "nodeId": "[#fbbeb]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 48.0},
          "value": false,
        },
        {
          "id": "in_2",
          "nodeId": "[#fbbeb]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 64.0},
          "value": false,
        },
      ],
      "outputPins": [
        {
          "id": "out_0",
          "nodeId": "[#fbbeb]",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "out_1",
          "nodeId": "[#fbbeb]",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 48.0},
          "value": false,
        },
      ],
      "type": "composed",
      "reference": "full_adder",
    },
    {
      "id": "[#6fae2]",
      "position": {"dx": 288.0, "dy": 448.0},
      "inputPins": [
        {
          "id": "in_0",
          "nodeId": "[#6fae2]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "in_1",
          "nodeId": "[#6fae2]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 48.0},
          "value": false,
        },
        {
          "id": "in_2",
          "nodeId": "[#6fae2]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 64.0},
          "value": false,
        },
      ],
      "outputPins": [
        {
          "id": "out_0",
          "nodeId": "[#6fae2]",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "out_1",
          "nodeId": "[#6fae2]",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 48.0},
          "value": false,
        },
      ],
      "type": "composed",
      "reference": "full_adder",
    },
    {
      "id": "[#98e1c]",
      "position": {"dx": 288.0, "dy": 576.0},
      "inputPins": [
        {
          "id": "in_0",
          "nodeId": "[#98e1c]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "in_1",
          "nodeId": "[#98e1c]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 48.0},
          "value": false,
        },
        {
          "id": "in_2",
          "nodeId": "[#98e1c]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 64.0},
          "value": false,
        },
      ],
      "outputPins": [
        {
          "id": "out_0",
          "nodeId": "[#98e1c]",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "out_1",
          "nodeId": "[#98e1c]",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 48.0},
          "value": false,
        },
      ],
      "type": "composed",
      "reference": "full_adder",
    },
    {
      "id": "[#54f04]",
      "position": {"dx": 288.0, "dy": 704.0},
      "inputPins": [
        {
          "id": "in_0",
          "nodeId": "[#54f04]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "in_1",
          "nodeId": "[#54f04]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 48.0},
          "value": false,
        },
        {
          "id": "in_2",
          "nodeId": "[#54f04]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 64.0},
          "value": false,
        },
      ],
      "outputPins": [
        {
          "id": "out_0",
          "nodeId": "[#54f04]",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "out_1",
          "nodeId": "[#54f04]",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 48.0},
          "value": false,
        },
      ],
      "type": "composed",
      "reference": "full_adder",
    },
    {
      "id": "[#536c7]",
      "position": {"dx": 288.0, "dy": 832.0},
      "inputPins": [
        {
          "id": "in_0",
          "nodeId": "[#536c7]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "in_1",
          "nodeId": "[#536c7]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 48.0},
          "value": false,
        },
        {
          "id": "in_2",
          "nodeId": "[#536c7]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 64.0},
          "value": false,
        },
      ],
      "outputPins": [
        {
          "id": "out_0",
          "nodeId": "[#536c7]",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "out_1",
          "nodeId": "[#536c7]",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 48.0},
          "value": false,
        },
      ],
      "type": "composed",
      "reference": "full_adder",
    },
    {
      "id": "[#e9a29]",
      "position": {"dx": 288.0, "dy": 960.0},
      "inputPins": [
        {
          "id": "in_0",
          "nodeId": "[#e9a29]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "in_1",
          "nodeId": "[#e9a29]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 48.0},
          "value": false,
        },
        {
          "id": "in_2",
          "nodeId": "[#e9a29]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 64.0},
          "value": false,
        },
      ],
      "outputPins": [
        {
          "id": "out_0",
          "nodeId": "[#e9a29]",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "out_1",
          "nodeId": "[#e9a29]",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 48.0},
          "value": false,
        },
      ],
      "type": "composed",
      "reference": "full_adder",
    },
    {
      "id": "[#8f023]",
      "position": {"dx": 288.0, "dy": 1088.0},
      "inputPins": [
        {
          "id": "in_0",
          "nodeId": "[#8f023]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "in_1",
          "nodeId": "[#8f023]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 48.0},
          "value": false,
        },
        {
          "id": "in_2",
          "nodeId": "[#8f023]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 64.0},
          "value": false,
        },
      ],
      "outputPins": [
        {
          "id": "out_0",
          "nodeId": "[#8f023]",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "out_1",
          "nodeId": "[#8f023]",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 48.0},
          "value": false,
        },
      ],
      "type": "composed",
      "reference": "full_adder",
    },
    {
      "id": "[#56aef]",
      "position": {"dx": -256.0, "dy": 192.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#56aef]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "A1",
    },
    {
      "id": "[#848a2]",
      "position": {"dx": -256.0, "dy": 256.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#848a2]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "A2",
    },
    {
      "id": "[#97423]",
      "position": {"dx": -256.0, "dy": 320.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#97423]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "A4",
    },
    {
      "id": "[#0e715]",
      "position": {"dx": -256.0, "dy": 384.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#0e715]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "A8",
    },
    {
      "id": "[#ee02d]",
      "position": {"dx": -256.0, "dy": 448.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#ee02d]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "A16",
    },
    {
      "id": "[#35a64]",
      "position": {"dx": -256.0, "dy": 512.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#35a64]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "A32",
    },
    {
      "id": "[#897b4]",
      "position": {"dx": -256.0, "dy": 576.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#897b4]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "A64",
    },
    {
      "id": "[#3db01]",
      "position": {"dx": -256.0, "dy": 640.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#3db01]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "A128",
    },
    {
      "id": "[#43d9f]",
      "position": {"dx": -256.0, "dy": 768.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#43d9f]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "B1",
    },
    {
      "id": "[#9e048]",
      "position": {"dx": -256.0, "dy": 832.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#9e048]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "B2",
    },
    {
      "id": "[#d6244]",
      "position": {"dx": -256.0, "dy": 896.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#d6244]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "B4",
    },
    {
      "id": "[#e1521]",
      "position": {"dx": -256.0, "dy": 960.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#e1521]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "B8",
    },
    {
      "id": "[#dbe74]",
      "position": {"dx": -256.0, "dy": 1024.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#dbe74]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "B16",
    },
    {
      "id": "[#fbae6]",
      "position": {"dx": -256.0, "dy": 1088.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#fbae6]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "B32",
    },
    {
      "id": "[#f9e21]",
      "position": {"dx": -256.0, "dy": 1152.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#f9e21]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "B64",
    },
    {
      "id": "[#f1379]",
      "position": {"dx": -256.0, "dy": 1216.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#f1379]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "B128",
    },
    {
      "id": "[#f6e5e]",
      "position": {"dx": 672.0, "dy": 192.0},
      "inputPins": [
        {
          "id": "in",
          "nodeId": "[#f6e5e]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
      ],
      "outputPins": [],
      "type": "output",
      "value": false,
      "label": "O1",
    },
    {
      "id": "[#e58cd]",
      "position": {"dx": 672.0, "dy": 256.0},
      "inputPins": [
        {
          "id": "in",
          "nodeId": "[#e58cd]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
      ],
      "outputPins": [],
      "type": "output",
      "value": false,
      "label": "O2",
    },
    {
      "id": "[#ca193]",
      "position": {"dx": 672.0, "dy": 320.0},
      "inputPins": [
        {
          "id": "in",
          "nodeId": "[#ca193]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
      ],
      "outputPins": [],
      "type": "output",
      "value": false,
      "label": "O4",
    },
    {
      "id": "[#86e23]",
      "position": {"dx": 672.0, "dy": 384.0},
      "inputPins": [
        {
          "id": "in",
          "nodeId": "[#86e23]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
      ],
      "outputPins": [],
      "type": "output",
      "value": false,
      "label": "O8",
    },
    {
      "id": "[#522b6]",
      "position": {"dx": 672.0, "dy": 448.0},
      "inputPins": [
        {
          "id": "in",
          "nodeId": "[#522b6]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
      ],
      "outputPins": [],
      "type": "output",
      "value": false,
      "label": "O16",
    },
    {
      "id": "[#b89d5]",
      "position": {"dx": 672.0, "dy": 512.0},
      "inputPins": [
        {
          "id": "in",
          "nodeId": "[#b89d5]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
      ],
      "outputPins": [],
      "type": "output",
      "value": false,
      "label": "O32",
    },
    {
      "id": "[#db9d6]",
      "position": {"dx": 672.0, "dy": 576.0},
      "inputPins": [
        {
          "id": "in",
          "nodeId": "[#db9d6]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
      ],
      "outputPins": [],
      "type": "output",
      "value": false,
      "label": "O64",
    },
    {
      "id": "[#29db6]",
      "position": {"dx": 672.0, "dy": 640.0},
      "inputPins": [
        {
          "id": "in",
          "nodeId": "[#29db6]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
      ],
      "outputPins": [],
      "type": "output",
      "value": false,
      "label": "O128",
    },
    {
      "id": "[#e6dc4]",
      "position": {"dx": 672.0, "dy": 1104.0},
      "inputPins": [
        {
          "id": "in",
          "nodeId": "[#e6dc4]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
      ],
      "outputPins": [],
      "type": "output",
      "value": false,
      "label": "C-OUT",
    },
    {
      "id": "[#7b0a7]",
      "position": {"dx": -256.0, "dy": 64.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#7b0a7]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "C-IN",
    },
  ],
  "wires": [
    {
      "id": "[#b5174]",
      "fromNodeId": "[#56aef]",
      "fromPinId": "out",
      "toNodeId": "[#ab871]",
      "toPinId": "in_0",
      "waypoints": [],
    },
    {
      "id": "[#3cf25]",
      "fromNodeId": "[#848a2]",
      "fromPinId": "out",
      "toNodeId": "[#fbbeb]",
      "toPinId": "in_0",
      "waypoints": [
        {"dx": 256.0, "dy": 288.0},
        {"dx": 256.0, "dy": 352.0},
      ],
    },
    {
      "id": "[#0c1c9]",
      "fromNodeId": "[#97423]",
      "fromPinId": "out",
      "toNodeId": "[#6fae2]",
      "toPinId": "in_0",
      "waypoints": [
        {"dx": 240.0, "dy": 352.0},
        {"dx": 240.0, "dy": 480.0},
      ],
    },
    {
      "id": "[#3f9d0]",
      "fromNodeId": "[#0e715]",
      "fromPinId": "out",
      "toNodeId": "[#98e1c]",
      "toPinId": "in_0",
      "waypoints": [
        {"dx": 224.0, "dy": 416.0},
        {"dx": 224.0, "dy": 608.0},
      ],
    },
    {
      "id": "[#e35b3]",
      "fromNodeId": "[#ee02d]",
      "fromPinId": "out",
      "toNodeId": "[#54f04]",
      "toPinId": "in_0",
      "waypoints": [
        {"dx": 208.0, "dy": 480.0},
        {"dx": 208.0, "dy": 736.0},
      ],
    },
    {
      "id": "[#35370]",
      "fromNodeId": "[#35a64]",
      "fromPinId": "out",
      "toNodeId": "[#536c7]",
      "toPinId": "in_0",
      "waypoints": [
        {"dx": 192.0, "dy": 544.0},
        {"dx": 192.0, "dy": 864.0},
      ],
    },
    {
      "id": "[#b4701]",
      "fromNodeId": "[#897b4]",
      "fromPinId": "out",
      "toNodeId": "[#e9a29]",
      "toPinId": "in_0",
      "waypoints": [
        {"dx": 176.0, "dy": 608.0},
        {"dx": 176.0, "dy": 992.0},
      ],
    },
    {
      "id": "[#60961]",
      "fromNodeId": "[#3db01]",
      "fromPinId": "out",
      "toNodeId": "[#8f023]",
      "toPinId": "in_0",
      "waypoints": [
        {"dx": 160.0, "dy": 672.0},
        {"dx": 160.0, "dy": 1120.0},
      ],
    },
    {
      "id": "[#71bfd]",
      "fromNodeId": "[#43d9f]",
      "fromPinId": "out",
      "toNodeId": "[#ab871]",
      "toPinId": "in_1",
      "waypoints": [
        {"dx": 16.0, "dy": 800.0},
        {"dx": 16.0, "dy": 240.0},
      ],
    },
    {
      "id": "[#16063]",
      "fromNodeId": "[#9e048]",
      "fromPinId": "out",
      "toNodeId": "[#fbbeb]",
      "toPinId": "in_1",
      "waypoints": [
        {"dx": 32.0, "dy": 864.0},
        {"dx": 32.0, "dy": 368.0},
      ],
    },
    {
      "id": "[#557c8]",
      "fromNodeId": "[#d6244]",
      "fromPinId": "out",
      "toNodeId": "[#6fae2]",
      "toPinId": "in_1",
      "waypoints": [
        {"dx": 48.0, "dy": 928.0},
        {"dx": 48.0, "dy": 496.0},
      ],
    },
    {
      "id": "[#f9bfd]",
      "fromNodeId": "[#e1521]",
      "fromPinId": "out",
      "toNodeId": "[#98e1c]",
      "toPinId": "in_1",
      "waypoints": [
        {"dx": 64.0, "dy": 992.0},
        {"dx": 64.0, "dy": 624.0},
      ],
    },
    {
      "id": "[#a5cb3]",
      "fromNodeId": "[#dbe74]",
      "fromPinId": "out",
      "toNodeId": "[#54f04]",
      "toPinId": "in_1",
      "waypoints": [
        {"dx": 80.0, "dy": 1056.0},
        {"dx": 80.0, "dy": 752.0},
      ],
    },
    {
      "id": "[#e317b]",
      "fromNodeId": "[#f9e21]",
      "fromPinId": "out",
      "toNodeId": "[#e9a29]",
      "toPinId": "in_1",
      "waypoints": [
        {"dx": 112.0, "dy": 1184.0},
        {"dx": 112.0, "dy": 1008.0},
      ],
    },
    {
      "id": "[#f4f93]",
      "fromNodeId": "[#f1379]",
      "fromPinId": "out",
      "toNodeId": "[#8f023]",
      "toPinId": "in_1",
      "waypoints": [
        {"dx": 128.0, "dy": 1248.0},
        {"dx": 128.0, "dy": 1136.0},
      ],
    },
    {
      "id": "[#63e02]",
      "fromNodeId": "[#ab871]",
      "fromPinId": "out_0",
      "toNodeId": "[#f6e5e]",
      "toPinId": "in",
      "waypoints": [],
    },
    {
      "id": "[#37025]",
      "fromNodeId": "[#fbbeb]",
      "fromPinId": "out_0",
      "toNodeId": "[#e58cd]",
      "toPinId": "in",
      "waypoints": [
        {"dx": 560.0, "dy": 352.0},
        {"dx": 560.0, "dy": 288.0},
      ],
    },
    {
      "id": "[#31320]",
      "fromNodeId": "[#6fae2]",
      "fromPinId": "out_0",
      "toNodeId": "[#ca193]",
      "toPinId": "in",
      "waypoints": [
        {"dx": 576.0, "dy": 480.0},
        {"dx": 576.0, "dy": 352.0},
      ],
    },
    {
      "id": "[#e1702]",
      "fromNodeId": "[#98e1c]",
      "fromPinId": "out_0",
      "toNodeId": "[#86e23]",
      "toPinId": "in",
      "waypoints": [
        {"dx": 592.0, "dy": 608.0},
        {"dx": 592.0, "dy": 416.0},
      ],
    },
    {
      "id": "[#ac427]",
      "fromNodeId": "[#536c7]",
      "fromPinId": "out_0",
      "toNodeId": "[#b89d5]",
      "toPinId": "in",
      "waypoints": [
        {"dx": 624.0, "dy": 864.0},
        {"dx": 624.0, "dy": 544.0},
      ],
    },
    {
      "id": "[#ccafd]",
      "fromNodeId": "[#54f04]",
      "fromPinId": "out_0",
      "toNodeId": "[#522b6]",
      "toPinId": "in",
      "waypoints": [
        {"dx": 608.0, "dy": 736.0},
        {"dx": 608.0, "dy": 480.0},
      ],
    },
    {
      "id": "[#f5126]",
      "fromNodeId": "[#e9a29]",
      "fromPinId": "out_0",
      "toNodeId": "[#db9d6]",
      "toPinId": "in",
      "waypoints": [
        {"dx": 640.0, "dy": 992.0},
        {"dx": 640.0, "dy": 608.0},
      ],
    },
    {
      "id": "[#883e8]",
      "fromNodeId": "[#8f023]",
      "fromPinId": "out_0",
      "toNodeId": "[#29db6]",
      "toPinId": "in",
      "waypoints": [
        {"dx": 656.0, "dy": 1120.0},
        {"dx": 656.0, "dy": 672.0},
      ],
    },
    {
      "id": "[#0c501]",
      "fromNodeId": "[#ab871]",
      "fromPinId": "out_1",
      "toNodeId": "[#fbbeb]",
      "toPinId": "in_2",
      "waypoints": [
        {"dx": 464.0, "dy": 240.0},
        {"dx": 464.0, "dy": 304.0},
        {"dx": 272.0, "dy": 304.0},
        {"dx": 272.0, "dy": 384.0},
      ],
    },
    {
      "id": "[#5407e]",
      "fromNodeId": "[#fbbeb]",
      "fromPinId": "out_1",
      "toNodeId": "[#6fae2]",
      "toPinId": "in_2",
      "waypoints": [
        {"dx": 464.0, "dy": 368.0},
        {"dx": 464.0, "dy": 432.0},
        {"dx": 272.0, "dy": 432.0},
        {"dx": 272.0, "dy": 512.0},
      ],
    },
    {
      "id": "[#42e22]",
      "fromNodeId": "[#98e1c]",
      "fromPinId": "out_1",
      "toNodeId": "[#54f04]",
      "toPinId": "in_2",
      "waypoints": [
        {"dx": 464.0, "dy": 624.0},
        {"dx": 464.0, "dy": 688.0},
        {"dx": 272.0, "dy": 688.0},
        {"dx": 272.0, "dy": 768.0},
      ],
    },
    {
      "id": "[#7c123]",
      "fromNodeId": "[#54f04]",
      "fromPinId": "out_1",
      "toNodeId": "[#536c7]",
      "toPinId": "in_2",
      "waypoints": [
        {"dx": 464.0, "dy": 752.0},
        {"dx": 464.0, "dy": 816.0},
        {"dx": 272.0, "dy": 816.0},
        {"dx": 272.0, "dy": 896.0},
      ],
    },
    {
      "id": "[#edb21]",
      "fromNodeId": "[#536c7]",
      "fromPinId": "out_1",
      "toNodeId": "[#e9a29]",
      "toPinId": "in_2",
      "waypoints": [
        {"dx": 464.0, "dy": 880.0},
        {"dx": 464.0, "dy": 944.0},
        {"dx": 272.0, "dy": 944.0},
        {"dx": 272.0, "dy": 1024.0},
      ],
    },
    {
      "id": "[#c2ace]",
      "fromNodeId": "[#e9a29]",
      "fromPinId": "out_1",
      "toNodeId": "[#8f023]",
      "toPinId": "in_2",
      "waypoints": [
        {"dx": 464.0, "dy": 1008.0},
        {"dx": 464.0, "dy": 1072.0},
        {"dx": 272.0, "dy": 1072.0},
        {"dx": 272.0, "dy": 1152.0},
      ],
    },
    {
      "id": "[#07963]",
      "fromNodeId": "[#8f023]",
      "fromPinId": "out_1",
      "toNodeId": "[#e6dc4]",
      "toPinId": "in",
      "waypoints": [],
    },
    {
      "id": "[#595e1]",
      "fromNodeId": "[#fbae6]",
      "fromPinId": "out",
      "toNodeId": "[#536c7]",
      "toPinId": "in_1",
      "waypoints": [
        {"dx": 96.0, "dy": 1120.0},
        {"dx": 96.0, "dy": 880.0},
      ],
    },
    {
      "id": "[#cf0b7]",
      "fromNodeId": "[#6fae2]",
      "fromPinId": "out_1",
      "toNodeId": "[#98e1c]",
      "toPinId": "in_2",
      "waypoints": [
        {"dx": 464.0, "dy": 496.0},
        {"dx": 464.0, "dy": 560.0},
        {"dx": 272.0, "dy": 560.0},
        {"dx": 272.0, "dy": 640.0},
      ],
    },
    {
      "id": "[#97dea]",
      "fromNodeId": "[#7b0a7]",
      "fromPinId": "out",
      "toNodeId": "[#ab871]",
      "toPinId": "in_2",
      "waypoints": [
        {"dx": 144.0, "dy": 96.0},
        {"dx": 144.0, "dy": 256.0},
      ],
    },
  ],
  "color": 4280171146,
  "inputLabels": [
    "A1",
    "A2",
    "A4",
    "A8",
    "A16",
    "A32",
    "A64",
    "A128",
    "B1",
    "B2",
    "B4",
    "B8",
    "B16",
    "B32",
    "B64",
    "B128",
    "C-IN",
  ],
  "outputLabels": [
    "O1",
    "O2",
    "O4",
    "O8",
    "O16",
    "O32",
    "O64",
    "O128",
    "C-OUT",
  ],
};

var k = {
  "id": "4way_and",
  "name": "4Way And",
  "nodes": [
    {
      "id": "[#0f8f5]",
      "position": {"dx": 304.0, "dy": 304.0},
      "inputPins": [
        {
          "id": "a",
          "nodeId": "[#0f8f5]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 16.0},
          "value": false,
        },
        {
          "id": "b",
          "nodeId": "[#0f8f5]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 48.0},
          "value": false,
        },
      ],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#0f8f5]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "gate",
      "gateType": "and",
    },
    {
      "id": "[#6444d]",
      "position": {"dx": 480.0, "dy": 320.0},
      "inputPins": [
        {
          "id": "a",
          "nodeId": "[#6444d]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 16.0},
          "value": false,
        },
        {
          "id": "b",
          "nodeId": "[#6444d]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 48.0},
          "value": false,
        },
      ],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#6444d]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "gate",
      "gateType": "and",
    },
    {
      "id": "[#4fe79]",
      "position": {"dx": 304.0, "dy": 448.0},
      "inputPins": [
        {
          "id": "a",
          "nodeId": "[#4fe79]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 16.0},
          "value": false,
        },
        {
          "id": "b",
          "nodeId": "[#4fe79]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 48.0},
          "value": false,
        },
      ],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#4fe79]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "gate",
      "gateType": "and",
    },
    {
      "id": "[#7d357]",
      "position": {"dx": 112.0, "dy": 272.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#7d357]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "A",
    },
    {
      "id": "[#68870]",
      "position": {"dx": 112.0, "dy": 352.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#68870]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "B",
    },
    {
      "id": "[#c4687]",
      "position": {"dx": 112.0, "dy": 432.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#c4687]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "C",
    },
    {
      "id": "[#633f6]",
      "position": {"dx": 112.0, "dy": 512.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "[#633f6]",
          "isInput": false,
          "localPosition": {"dx": 112.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "D",
    },
    {
      "id": "[#4eefc]",
      "position": {"dx": 672.0, "dy": 320.0},
      "inputPins": [
        {
          "id": "in",
          "nodeId": "[#4eefc]",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
      ],
      "outputPins": [],
      "type": "output",
      "value": false,
      "label": "Out",
    },
  ],
  "wires": [
    {
      "id": "[#7c1cd]",
      "fromNodeId": "[#7d357]",
      "fromPinId": "out",
      "toNodeId": "[#0f8f5]",
      "toPinId": "a",
      "waypoints": [
        {"dx": 288.0, "dy": 304.0},
        {"dx": 288.0, "dy": 320.0},
      ],
    },
    {
      "id": "[#9b0a8]",
      "fromNodeId": "[#68870]",
      "fromPinId": "out",
      "toNodeId": "[#0f8f5]",
      "toPinId": "b",
      "waypoints": [
        {"dx": 288.0, "dy": 384.0},
        {"dx": 288.0, "dy": 352.0},
      ],
    },
    {
      "id": "[#87680]",
      "fromNodeId": "[#c4687]",
      "fromPinId": "out",
      "toNodeId": "[#4fe79]",
      "toPinId": "a",
      "waypoints": [],
    },
    {
      "id": "[#3550a]",
      "fromNodeId": "[#633f6]",
      "fromPinId": "out",
      "toNodeId": "[#4fe79]",
      "toPinId": "b",
      "waypoints": [
        {"dx": 288.0, "dy": 544.0},
        {"dx": 288.0, "dy": 496.0},
      ],
    },
    {
      "id": "[#ab1fa]",
      "fromNodeId": "[#4fe79]",
      "fromPinId": "out",
      "toNodeId": "[#6444d]",
      "toPinId": "b",
      "waypoints": [
        {"dx": 464.0, "dy": 480.0},
        {"dx": 464.0, "dy": 368.0},
      ],
    },
    {
      "id": "[#6d730]",
      "fromNodeId": "[#0f8f5]",
      "fromPinId": "out",
      "toNodeId": "[#6444d]",
      "toPinId": "a",
      "waypoints": [],
    },
    {
      "id": "[#931d0]",
      "fromNodeId": "[#6444d]",
      "fromPinId": "out",
      "toNodeId": "[#4eefc]",
      "toPinId": "in",
      "waypoints": [],
    },
  ],
  "color": 4280171146,
  "inputLabels": ["A", "B", "C", "D"],
  "outputLabels": ["Out"],
};
