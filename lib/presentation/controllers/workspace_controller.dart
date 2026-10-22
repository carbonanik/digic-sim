import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'circuit_controller.dart';

@immutable
class Workspace {
  final String id;
  final String name;
  const Workspace({required this.id, required this.name});
}

@immutable
class WorkspaceState {
  final List<Workspace> workspaces;
  final int activeIndex;
  WorkspaceState({
    required List<Workspace> workspaces,
    required this.activeIndex,
  }) : workspaces = List.unmodifiable(workspaces);
  Workspace get activeWorkspace => workspaces[activeIndex];
}

final workspaceControllerProvider =
    NotifierProvider<WorkspaceController, WorkspaceState>(
      WorkspaceController.new,
    );

/// Owns tab metadata and the explicit open/close lifetime of each document.
class WorkspaceController extends Notifier<WorkspaceState> {
  int _nextWorkspaceId = 1;

  @override
  WorkspaceState build() => WorkspaceState(
    workspaces: [const Workspace(id: 'workspace_0', name: 'Main Workspace')],
    activeIndex: 0,
  );

  List<Workspace> get workspaces => state.workspaces;
  int get activeIndex => state.activeIndex;
  Workspace get activeWorkspace => state.activeWorkspace;
  CircuitController get activeController => controllerFor(activeWorkspace.id);
  CircuitController controllerFor(String id) =>
      ref.read(circuitControllerProvider(id).notifier);

  void addWorkspace(String name) {
    final workspace = Workspace(
      id: 'workspace_${_nextWorkspaceId++}',
      name: name,
    );
    state = WorkspaceState(
      workspaces: [...state.workspaces, workspace],
      activeIndex: state.workspaces.length,
    );
  }

  void switchWorkspace(int index) {
    if (index < 0 ||
        index >= state.workspaces.length ||
        index == state.activeIndex) {
      return;
    }
    state = WorkspaceState(workspaces: state.workspaces, activeIndex: index);
  }

  void closeWorkspace(int index) {
    if (index < 0 || index >= state.workspaces.length) return;
    final closed = state.workspaces[index];
    controllerFor(closed.id).close();
    final remaining = [...state.workspaces]..removeAt(index);
    if (remaining.isEmpty) {
      remaining.add(
        Workspace(
          id: 'workspace_${_nextWorkspaceId++}',
          name: 'Main Workspace',
        ),
      );
    }
    var activeIndex = state.activeIndex;
    if (index < activeIndex) activeIndex--;
    if (activeIndex >= remaining.length) activeIndex = remaining.length - 1;
    state = WorkspaceState(workspaces: remaining, activeIndex: activeIndex);
  }

  void renameWorkspace(int index, String newName) {
    if (index < 0 || index >= state.workspaces.length) return;
    state = WorkspaceState(
      workspaces: [
        for (var i = 0; i < state.workspaces.length; i++)
          if (i == index)
            Workspace(id: state.workspaces[i].id, name: newName)
          else
            state.workspaces[i],
      ],
      activeIndex: state.activeIndex,
    );
  }
}
