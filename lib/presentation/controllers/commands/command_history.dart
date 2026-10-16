import 'package:digital_logic_sim_2/domain/entities/circuit.dart';
import 'package:digital_logic_sim_2/presentation/controllers/commands/circuit_command.dart';

/// Manages undo and redo stacks for circuit commands.
class CommandHistory {
  final List<CircuitCommand> _undoStack = [];
  final List<CircuitCommand> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  /// Executes a command, applying it to [circuit], and records it in history.
  void execute(CircuitCommand command, Circuit circuit) {
    command.execute(circuit);
    _undoStack.add(command);
    _redoStack.clear();
  }

  /// Pushes an already-executed command into history.
  void push(CircuitCommand command) {
    _undoStack.add(command);
    _redoStack.clear();
  }

  /// Reverts the most recent command.
  bool undo(Circuit circuit) {
    if (_undoStack.isEmpty) return false;
    final command = _undoStack.removeLast();
    command.undo(circuit);
    _redoStack.add(command);
    return true;
  }

  /// Re-applies the most recently undone command.
  bool redo(Circuit circuit) {
    if (_redoStack.isEmpty) return false;
    final command = _redoStack.removeLast();
    command.execute(circuit);
    _undoStack.add(command);
    return true;
  }

  /// Clears undo and redo histories.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
