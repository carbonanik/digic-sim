import 'package:flutter/material.dart';

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
              icon: Icons.cable,
              label: 'Wire',
              selected: controller.selectedTool == EditorTool.wire,
              onTap: () => controller.selectTool(EditorTool.wire),
            ),
            _ToolButton(
              icon: Icons.delete_forever,
              label: 'Delete Selected',
              selected: false,
              onTap: () => controller.deleteSelected(),
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
            if (controller.customDefinitions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Saved ICs',
                style: TextStyle(
                  color: Color(0xff94a3b8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...controller.customDefinitions.map((def) => _ToolButton(
                    icon: Icons.developer_board,
                    label: def.name,
                    selected: false,
                    onTap: () => controller.addCustomComponent(def, const Offset(100, 100)),
                  )),
            ],
            const _HintCard(),
          ],
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

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
        'Tip: Select a component, tap canvas to place it. Use Wire tool to connect pins. Select and press Delete/Backspace to remove items.',
        style: TextStyle(color: Color(0xff94a3b8), height: 1.4, fontSize: 13),
      ),
    );
  }
}
