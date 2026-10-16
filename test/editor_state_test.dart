import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_logic_sim_2/presentation/controllers/editor_state.dart';
import 'package:digital_logic_sim_2/presentation/tools/editor_tools.dart';

void main() {
  group('EditorState tests', () {
    test('Default initial state', () {
      final state = EditorState();
      expect(state.selectedTool, EditorTool.select);
      expect(state.selectedNodeIds, isEmpty);
      expect(state.selectedWireId, isNull);
      expect(state.hoveredNodeId, isNull);
      expect(state.hoveredPin, isNull);
      expect(state.mousePosition, isNull);
    });

    test('clearSelection resets selection fields', () {
      final state = EditorState()
        ..selectedNodeIds = {'node1', 'node2'}
        ..selectedWireId = 'wire1'
        ..selectionRect = const Rect.fromLTWH(0, 0, 100, 100);

      state.clearSelection();

      expect(state.selectedNodeIds, isEmpty);
      expect(state.selectedWireId, isNull);
      expect(state.selectionRect, isNull);
    });

    test('reset clears tool and state', () {
      final state = EditorState()
        ..selectedTool = EditorTool.and
        ..selectedNodeIds = {'node1'};

      state.reset();

      expect(state.selectedTool, EditorTool.select);
      expect(state.selectedNodeIds, isEmpty);
    });
  });
}
