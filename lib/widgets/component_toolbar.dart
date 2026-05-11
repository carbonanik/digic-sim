import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/circuit_controller.dart';
import '../editor/editor_tools.dart';

class ComponentToolbar extends StatelessWidget {
  final CircuitController controller;

  const ComponentToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xff0b1120),
        border: Border(right: BorderSide(color: Color(0xff1f2937))),
      ),
      child: SingleChildScrollView(
        // Wrap the Column with SingleChildScrollView
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AppLogo(),
            const SizedBox(height: 24),
            const Text(
              'Components',
              style: TextStyle(
                color: Color(0xff94a3b8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _ToolButton(
              icon: Icons.mouse,
              label: 'Select / Move',
              selected: controller.selectedTool == EditorTool.select,
              onTap: () => controller.selectTool(EditorTool.select),
            ),
            _ToolButton(
              icon: Icons.delete_forever,
              label: 'Delete Selected',
              selected: false,
              onTap: () => controller.deleteSelected(),
            ),
            _ToolButton(
              icon: Icons.layers_clear,
              label: 'Clear Canvas',
              selected: false,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xff0b1120),
                    title: const Text(
                      'Clear Canvas?',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'This will delete everything on the canvas. Continue?',
                      style: TextStyle(color: Color(0xff94a3b8)),
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
                        ),
                        child: const Text('Clear Everything'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Inputs / Outputs',
              style: TextStyle(
                color: Color(0xff94a3b8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _ToolButton(
              icon: Icons.input,
              label: 'Input',
              selected: controller.selectedTool == EditorTool.input,
              onTap: () => controller.selectTool(EditorTool.input),
            ),
            _ToolButton(
              icon: Icons.output,
              label: 'Output',
              selected: controller.selectedTool == EditorTool.output,
              onTap: () => controller.selectTool(EditorTool.output),
            ),
            const SizedBox(height: 16),
            const Text(
              'Logic Gates',
              style: TextStyle(
                color: Color(0xff94a3b8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _ToolButton(
              icon: Icons.join_inner,
              label: 'AND Gate',
              selected: controller.selectedTool == EditorTool.and,
              onTap: () => controller.selectTool(EditorTool.and),
            ),
            _ToolButton(
              icon: Icons.call_split,
              label: 'OR Gate',
              selected: controller.selectedTool == EditorTool.or,
              onTap: () => controller.selectTool(EditorTool.or),
            ),
            _ToolButton(
              icon: Icons.change_circle_outlined,
              label: 'NOT Gate',
              selected: controller.selectedTool == EditorTool.not,
              onTap: () => controller.selectTool(EditorTool.not),
            ),
            _ToolButton(
              icon: Icons.join_full,
              label: 'NAND Gate',
              selected: controller.selectedTool == EditorTool.nand,
              onTap: () => controller.selectTool(EditorTool.nand),
            ),
            _ToolButton(
              icon: Icons.device_hub,
              label: 'NOR Gate',
              selected: controller.selectedTool == EditorTool.nor,
              onTap: () => controller.selectTool(EditorTool.nor),
            ),
            _ToolButton(
              icon: Icons.merge,
              label: 'XOR Gate',
              selected: controller.selectedTool == EditorTool.xor,
              onTap: () => controller.selectTool(EditorTool.xor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Complex Components',
              style: TextStyle(
                color: Color(0xff94a3b8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _ToolButton(
              icon: Icons.display_settings,
              label: '7-Segment Display',
              selected: controller.selectedTool == EditorTool.segmentDisplay,
              onTap: () => controller.selectTool(EditorTool.segmentDisplay),
            ),
            _ToolButton(
              icon: Icons.timer,
              label: 'Clock (1Hz)',
              selected: controller.selectedTool == EditorTool.clock,
              onTap: () => controller.selectTool(EditorTool.clock),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saved ICs',
                  style: TextStyle(
                    color: Color(0xff94a3b8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showImportDialog(context),
                  icon: const Icon(Icons.upload, size: 14),
                  label: const Text('Import', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (controller.customDefinitions.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 16, left: 4),
                child: Text(
                  'Import a JSON to see it here',
                  style: TextStyle(
                    color: Color(0xff4b5563),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ...controller.customDefinitions.map(
              (def) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xff111827),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xff1f2937)),
                  ),
                  child: Column(
                    children: [
                      _ToolButton(
                        icon: Icons.developer_board,
                        label: def.name,
                        selected:
                            controller.selectedTool == EditorTool.custom &&
                            controller.selectedCustomComponent == def,
                        margin: EdgeInsets.zero,
                        onTap: () => controller.selectCustomComponent(def),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _SmallIconButton(
                            icon: Icons.visibility,
                            tooltip: 'Open in Canvas',
                            onTap: () => controller.loadDefinition(def),
                          ),
                          _SmallIconButton(
                            icon: Icons.copy_all,
                            tooltip: 'Copy JSON',
                            onTap: () {
                              final json = controller.exportIC(def);
                              Clipboard.setData(ClipboardData(text: json));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${def.name} JSON copied!'),
                                  behavior: SnackBarBehavior.floating,
                                  width: 200,
                                ),
                              );
                            },
                          ),
                          _SmallIconButton(
                            icon: Icons.delete_outline,
                            tooltip: 'Delete IC',
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xff0b1120),
                                  title: const Text(
                                    'Delete IC?',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: Text(
                                    'Are you sure you want to delete "${def.name}"?',
                                    style: const TextStyle(
                                      color: Color(0xff94a3b8),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        controller.removeCustomDefinition(def);
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade900,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const _HintCard(),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff0b1120),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Import Custom IC',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste the JSON definition of your custom component below:',
              style: TextStyle(color: Color(0xff94a3b8), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              maxLines: 6,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
              decoration: InputDecoration(
                hintText: '{"name": "My IC", ...}',
                hintStyle: const TextStyle(color: Color(0xff4b5563)),
                fillColor: const Color(0xff020617),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xff1f2937)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xff1f2937)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xff38bdf8)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xff94a3b8)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                controller.importIC(textController.text.trim());
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff2563eb),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Import Component'),
          ),
        ],
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SmallIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xff1f2937),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xff94a3b8)),
        ),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: const Color(0xff38bdf8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.schema, color: Color(0xff020617)),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Logic Lab',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final EdgeInsets? margin;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xff1e40af) : const Color(0xff111827),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected
                    ? const Color(0xff60a5fa)
                    : const Color(0xff1f2937),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? const Color(0xffdbeafe)
                      : const Color(0xff94a3b8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xffffffff)
                          : const Color(0xffcbd5e1),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xff1f2937)),
      ),
      child: const Text(
        'Tip: Select a component, tap canvas to place it. Drag from any Pin to create a wire instantly! Select and press Delete/Backspace to remove items.',
        style: TextStyle(color: Color(0xff94a3b8), height: 1.4, fontSize: 13),
      ),
    );
  }
}
