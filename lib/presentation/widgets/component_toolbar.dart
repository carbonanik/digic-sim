import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';
import 'package:digital_logic_sim_2/features/component_library/preset_library.dart';
import 'package:digital_logic_sim_2/presentation/controllers/circuit_controller.dart';
import 'package:digital_logic_sim_2/presentation/controllers/workspace_controller.dart';
import 'package:digital_logic_sim_2/presentation/tools/editor_tools.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ComponentToolbar extends StatelessWidget {
  final CircuitController controller;
  final WorkspaceController workspaceController;

  const ComponentToolbar({
    super.key,
    required this.controller,
    required this.workspaceController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: const Color(0xff0b1120).withOpacity(0.95),
        border: const Border(right: BorderSide(color: Color(0xff1f2937))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: _AppLogo(),
          ),
          const Divider(color: Color(0xff1f2937), height: 1),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SectionHeader(
                        title: 'EDITOR TOOLS',
                        icon: Icons.edit_note,
                        onAction: () =>
                            controller.selectTool(EditorTool.select),
                        actionLabel: 'Reset',
                      ),
                      _ToolButton(
                        icon: Icons.mouse_outlined,
                        label: 'Selection Mode',
                        shortcut: 'S',
                        selected: controller.selectedTool == EditorTool.select,
                        onTap: () => controller.selectTool(EditorTool.select),
                      ),
                      _ToolButton(
                        icon: Icons.delete_outline,
                        label: 'Delete Selected',
                        shortcut: 'Del',
                        selected: false,
                        onTap: () => controller.deleteSelected(),
                        activeColor: Colors.redAccent.withOpacity(0.2),
                      ),
                      const SizedBox(height: 20),
                      const _SectionHeader(
                        title: 'IO COMPONENTS',
                        icon: Icons.settings_input_component,
                      ),
                      _ToolButton(
                        icon: Icons.login_outlined,
                        label: 'Input Switch',
                        selected: controller.selectedTool == EditorTool.input,
                        onTap: () => controller.selectTool(EditorTool.input),
                      ),
                      _ToolButton(
                        icon: Icons.logout_outlined,
                        label: 'Output Bulb',
                        selected: controller.selectedTool == EditorTool.output,
                        onTap: () => controller.selectTool(EditorTool.output),
                      ),
                      _ToolButton(
                        icon: Icons.timer_outlined,
                        label: 'Clock Generator',
                        selected: controller.selectedTool == EditorTool.clock,
                        onTap: () => controller.selectTool(EditorTool.clock),
                      ),
                      const SizedBox(height: 20),
                      const _SectionHeader(
                        title: 'LOGIC GATES',
                        icon: Icons.hub_outlined,
                      ),
                      _ToolButton(
                        icon: Icons.join_inner_outlined,
                        label: 'AND Gate',
                        selected: controller.selectedTool == EditorTool.and,
                        onTap: () => controller.selectTool(EditorTool.and),
                      ),
                      _ToolButton(
                        icon: Icons.call_split_outlined,
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
                        icon: Icons.join_full_outlined,
                        label: 'NAND Gate',
                        selected: controller.selectedTool == EditorTool.nand,
                        onTap: () => controller.selectTool(EditorTool.nand),
                      ),
                      _ToolButton(
                        icon: Icons.device_hub_outlined,
                        label: 'NOR Gate',
                        selected: controller.selectedTool == EditorTool.nor,
                        onTap: () => controller.selectTool(EditorTool.nor),
                      ),
                      _ToolButton(
                        icon: Icons.merge_outlined,
                        label: 'XOR Gate',
                        selected: controller.selectedTool == EditorTool.xor,
                        onTap: () => controller.selectTool(EditorTool.xor),
                      ),
                      const SizedBox(height: 20),
                      const _SectionHeader(
                        title: 'ADVANCED',
                        icon: Icons.biotech_outlined,
                      ),
                      _ToolButton(
                        icon: Icons.seven_mp_outlined,
                        label: '7-Seg Display',
                        selected:
                            controller.selectedTool ==
                            EditorTool.segmentDisplay,
                        onTap: () =>
                            controller.selectTool(EditorTool.segmentDisplay),
                      ),
                      _ToolButton(
                        icon: Icons.analytics_outlined,
                        label: 'Waveform Monitor',
                        selected:
                            controller.selectedTool == EditorTool.waveform,
                        onTap: () => controller.selectTool(EditorTool.waveform),
                      ),
                      _ToolButton(
                        icon: Icons.light_outlined,
                        label: 'RGB LED',
                        selected: controller.selectedTool == EditorTool.rgbLed,
                        onTap: () => controller.selectTool(EditorTool.rgbLed),
                      ),
                      _ToolButton(
                        icon: Icons.biotech_outlined,
                        label: 'Logic Probe',
                        selected:
                            controller.selectedTool == EditorTool.logicProbe,
                        onTap: () =>
                            controller.selectTool(EditorTool.logicProbe),
                      ),
                      const SizedBox(height: 20),
                      const _SectionHeader(
                        title: 'PRESET ICs',
                        icon: Icons.library_books_outlined,
                      ),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final def = PresetLibrary.presets[index];
                      return _ICCard(
                        def: def,
                        controller: controller,
                        workspaceController: workspaceController,
                        selected:
                            controller.selectedTool == EditorTool.custom &&
                            controller.selectedCustomComponent == def,
                        isPreset: true,
                      );
                    }, childCount: PresetLibrary.presets.length),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SectionHeader(
                        title: 'SAVED ICs',
                        icon: Icons.memory_outlined,
                        onAction: () => _showImportDialog(context),
                        actionLabel: 'Import',
                      ),
                      if (controller.customDefinitions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xff111827).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xff1f2937),
                              style: BorderStyle.none,
                            ),
                          ),
                          child: const Text(
                            'No custom components yet.',
                            style: TextStyle(
                              color: Color(0xff4b5563),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final def = controller.customDefinitions[index];
                      return _ICCard(
                        def: def,
                        controller: controller,
                        workspaceController: workspaceController,
                        selected:
                            controller.selectedTool == EditorTool.custom &&
                            controller.selectedCustomComponent == def,
                      );
                    }, childCount: controller.customDefinitions.length),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(child: _HintCard()),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff0b1120),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xff1f2937)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xff38bdf8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.file_download_outlined,
                color: Color(0xff38bdf8),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Import Component',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste the IC JSON definition below to add it to your library.',
              style: TextStyle(color: Color(0xff94a3b8), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              maxLines: 8,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
              decoration: InputDecoration(
                hintText: '{\n  "name": "My Component",\n  ...\n}',
                hintStyle: const TextStyle(color: Color(0xff4b5563)),
                fillColor: const Color(0xff020617),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xff1f2937)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xff1f2937)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xff38bdf8),
                    width: 2,
                  ),
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
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: ElevatedButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  controller.importIC(textController.text.trim());
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff38bdf8),
                foregroundColor: const Color(0xff020617),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Import Now',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xff4b5563)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xff64748b),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          if (onAction != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  actionLabel ?? 'Action',
                  style: const TextStyle(
                    color: Color(0xff38bdf8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? shortcut;
  final bool selected;
  final VoidCallback onTap;
  final Color? activeColor;

  const _ToolButton({
    required this.icon,
    required this.label,
    this.shortcut,
    required this.selected,
    required this.onTap,
    this.activeColor,
  });

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.selected;
    final Color primaryColor = widget.activeColor ?? const Color(0xff38bdf8);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withOpacity(0.15)
                : (_isHovered ? const Color(0xff1f2937) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? primaryColor.withOpacity(0.5)
                  : (_isHovered ? const Color(0xff374151) : Colors.transparent),
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  AnimatedScale(
                    scale: isSelected || _isHovered ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.icon,
                      size: 20,
                      color: isSelected
                          ? primaryColor
                          : (_isHovered
                                ? Colors.white
                                : const Color(0xff94a3b8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (_isHovered
                                  ? Colors.white
                                  : const Color(0xffcbd5e1)),
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.shortcut != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff020617),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xff1f2937)),
                      ),
                      child: Text(
                        widget.shortcut!,
                        style: const TextStyle(
                          color: Color(0xff4b5563),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ICCard extends StatelessWidget {
  final SubCircuitDefinition def;
  final CircuitController controller;
  final WorkspaceController workspaceController;
  final bool selected;
  final bool isPreset;

  const _ICCard({
    required this.def,
    required this.controller,
    required this.workspaceController,
    required this.selected,
    this.isPreset = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xff111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? const Color(0xff38bdf8).withOpacity(0.5)
              : const Color(0xff1f2937),
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          _ToolButton(
            icon: Icons.developer_board,
            label: def.name,
            selected: selected,
            onTap: () => controller.selectCustomComponent(def),
          ),
          const Divider(color: Color(0xff1f2937), height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SmallIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Open in New Workspace',
                  onTap: () {
                    workspaceController.addWorkspace(def.name);
                    workspaceController.activeController?.loadDefinition(def);
                  },
                ),
                _SmallIconButton(
                  icon: Icons.content_copy_outlined,
                  tooltip: 'Copy JSON',
                  onTap: () {
                    final json = controller.exportIC(def);
                    Clipboard.setData(ClipboardData(text: json));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${def.name} copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xff1e293b),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
                if (!isPreset)
                  _SmallIconButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Remove',
                    onTap: () => _confirmDelete(context),
                    color: Colors.redAccent.withOpacity(0.1),
                    iconColor: Colors.redAccent.shade100,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff0b1120),
        title: const Text('Delete IC?'),
        content: Text(
          'Remove "${def.name}" from your library? This cannot be undone.',
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
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  final Color? iconColor;

  const _SmallIconButton({
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
            color: color ?? const Color(0xff1f2937),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor ?? const Color(0xff94a3b8),
          ),
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
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff38bdf8), Color(0xff2563eb)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff38bdf8).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.bolt, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        const Text(
          'LOGIC LAB',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff1e293b).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xff334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: Color(0xfff59e0b)),
              SizedBox(width: 8),
              Text(
                'QUICK TIP',
                style: TextStyle(
                  color: Color(0xfff59e0b),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Drag from any Pin to create a wire instantly. Use Ctrl+Z to undo.',
            style: TextStyle(
              color: Color(0xff94a3b8),
              height: 1.5,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
