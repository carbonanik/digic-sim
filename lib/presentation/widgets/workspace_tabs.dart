import 'package:digital_logic_sim_2/presentation/controllers/workspace_controller.dart';
import 'package:flutter/material.dart';

class WorkspaceTabs extends StatelessWidget {
  final WorkspaceController workspaceController;

  const WorkspaceTabs({super.key, required this.workspaceController});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xff0b1120),
        border: Border(bottom: BorderSide(color: Color(0xff1f2937))),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: workspaceController.workspaces.length,
              itemBuilder: (context, index) {
                final workspace = workspaceController.workspaces[index];
                final isActive = workspaceController.activeIndex == index;

                return _TabItem(
                  name: workspace.name,
                  isActive: isActive,
                  onTap: () => workspaceController.switchWorkspace(index),
                  onClose: () => workspaceController.closeWorkspace(index),
                  onRename: (newName) =>
                      workspaceController.renameWorkspace(index, newName),
                );
              },
            ),
          ),
          _AddTabButton(
            onTap: () => workspaceController.addWorkspace('New Workspace'),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatefulWidget {
  final String name;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final Function(String) onRename;

  const _TabItem({
    required this.name,
    required this.isActive,
    required this.onTap,
    required this.onClose,
    required this.onRename,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _isHovered = false;
  bool _isEditing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.name);
  }

  @override
  void didUpdateWidget(_TabItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name && !_isEditing) {
      _editController.text = widget.name;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: () {
          setState(() {
            _isEditing = true;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
          margin: const EdgeInsets.only(top: 4, left: 4, right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: widget.isActive
                ? const Color(0xff1e293b)
                : _isHovered
                ? const Color(0xff1e293b).withOpacity(0.5)
                : Colors.transparent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border(
              bottom: BorderSide(
                color: widget.isActive
                    ? const Color(0xff38bdf8)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _isEditing
                    ? TextField(
                        controller: _editController,
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) {
                          widget.onRename(value);
                          setState(() => _isEditing = false);
                        },
                        onTapOutside: (_) {
                          widget.onRename(_editController.text);
                          setState(() => _isEditing = false);
                        },
                      )
                    : Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: widget.isActive
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: widget.isActive
                              ? Colors.white
                              : Colors.white70,
                        ),
                      ),
              ),
              if (_isHovered || widget.isActive)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  icon: const Icon(Icons.close, size: 14),
                  color: Colors.white38,
                  hoverColor: Colors.red.withOpacity(0.1),
                  onPressed: widget.onClose,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTabButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTabButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add, size: 20),
      color: Colors.white38,
      hoverColor: const Color(0xff38bdf8).withOpacity(0.1),
      onPressed: onTap,
    );
  }
}
