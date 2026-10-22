import 'package:flutter/material.dart';
import 'circuit_controller.dart';

class Workspace {
  final String id;
  String name;
  final CircuitController controller;

  Workspace({required this.id, required this.name, required this.controller});
}

class WorkspaceController extends ChangeNotifier {
  final CircuitController Function() _createCircuitController;
  final List<Workspace> _workspaces = [];
  int _nextWorkspaceId = 0;
  int _activeIndex = -1;

  List<Workspace> get workspaces => List.unmodifiable(_workspaces);
  int get activeIndex => _activeIndex;

  Workspace? get activeWorkspace =>
      (_activeIndex >= 0 && _activeIndex < _workspaces.length)
      ? _workspaces[_activeIndex]
      : null;

  CircuitController? get activeController => activeWorkspace?.controller;

  WorkspaceController({
    required CircuitController Function() createCircuitController,
  }) : _createCircuitController = createCircuitController {
    // Start with one workspace
    addWorkspace('Main Workspace');
  }

  void addWorkspace(String name) {
    final controller = _createCircuitController();
    final workspace = Workspace(
      id: 'workspace_${_nextWorkspaceId++}',
      name: name,
      controller: controller,
    );
    _workspaces.add(workspace);
    _activeIndex = _workspaces.length - 1;
    notifyListeners();
  }

  void switchWorkspace(int index) {
    if (index >= 0 && index < _workspaces.length) {
      _activeIndex = index;
      notifyListeners();
    }
  }

  void closeWorkspace(int index) {
    if (index >= 0 && index < _workspaces.length) {
      // If closing the last workspace, we might want to prevent it or add a new one.
      final workspace = _workspaces[index];
      workspace.controller.dispose();
      _workspaces.removeAt(index);

      if (_workspaces.isEmpty) {
        addWorkspace('Main Workspace');
        return;
      }
      if (index < _activeIndex) {
        _activeIndex--;
      } else if (_activeIndex >= _workspaces.length) {
        _activeIndex = _workspaces.length - 1;
      }
      notifyListeners();
    }
  }

  void renameWorkspace(int index, String newName) {
    if (index >= 0 && index < _workspaces.length) {
      _workspaces[index].name = newName;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final workspace in _workspaces) {
      workspace.controller.dispose();
    }
    super.dispose();
  }
}
