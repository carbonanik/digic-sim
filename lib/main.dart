import 'package:digital_logic_sim_2/models/nodes/io_nodes.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'controllers/circuit_controller.dart';
import 'editor/circuit_canvas.dart';
import 'editor/editor_tools.dart';
import 'widgets/component_toolbar.dart';

void main() {
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
  final CircuitController controller = CircuitController();

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.delete): () =>
            controller.deleteSelected(),
        const SingleActivator(LogicalKeyboardKey.backspace): () =>
            controller.deleteSelected(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return Row(
                children: [
                  ComponentToolbar(controller: controller),
                  Expanded(
                    child: Column(
                      children: [
                        _TopBar(controller: controller),
                        Expanded(child: CircuitCanvas(controller: controller)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final CircuitController controller;

  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final hasSelection = controller.selectedNodeIds.isNotEmpty || controller.selectedWireId != null;

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
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UNTITLED CIRCUIT',
                style: TextStyle(
                  color: Color(0xff4b5563),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Main Workspace',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
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
                tooltip: 'Redo (Ctrl+Y)',
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
                icon: controller.snapToGridEnabled ? Icons.grid_on_rounded : Icons.grid_off_rounded,
                label: 'Snap',
                active: controller.snapToGridEnabled,
                onTap: controller.toggleGridSnapping,
              ),
            ],
          ),
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
        content: const Text('This will delete all components and wires. This action is permanent.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      (_) => TextEditingController(),
    );
    final outputControllers = List.generate(
      outputNodes.length,
      (_) => TextEditingController(),
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
          child: Icon(icon, size: 20, color: iconColor ?? const Color(0xff94a3b8)),
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
          color: active ? const Color(0xff38bdf8).withOpacity(0.1) : Colors.transparent,
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
