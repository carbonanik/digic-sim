import 'dart:convert';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';
import 'package:digital_logic_sim_2/presentation/canvas/node_renderer.dart';
import 'package:digital_logic_sim_2/presentation/controllers/create_node_factory.dart';
import 'package:digital_logic_sim_2/presentation/tools/editor_tools.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Every built-in component renders without changing circuit state',
    () async {
      final factory = CreateNodeFactory();
      final nodes = <CircuitNode>[
        for (final tool in EditorTool.values)
          if (![
            EditorTool.select,
            EditorTool.wire,
            EditorTool.custom,
          ].contains(tool))
            factory.create(tool, const Offset(16, 16)),
        ComposedNode(
          id: 'ic',
          position: const Offset(16, 16),
          inputPins: [],
          outputPins: [],
          definition: SubCircuitDefinition(
            id: 'ic_def',
            name: 'IC',
            nodes: [],
            wires: [],
          ),
        ),
      ];
      for (final node in nodes) {
        final before = jsonEncode(node.toMap());
        for (final state in [(false, false), (true, false), (false, true)]) {
          final recorder = PictureRecorder();
          final canvas = Canvas(recorder);
          node.paint(canvas, state.$1, isHovered: state.$2);
          final picture = recorder.endRecording();
          final image = await picture.toImage(320, 256);
          final pixels = await image.toByteData();
          expect(
            pixels!.buffer.asUint8List().any((value) => value != 0),
            isTrue,
            reason: '${node.runtimeType} must draw pixels',
          );
          image.dispose();
          picture.dispose();
        }
        expect(jsonEncode(node.toMap()), before);
      }
    },
  );
}
