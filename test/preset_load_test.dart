import 'package:flutter_test/flutter_test.dart';
import 'package:digital_logic_sim_2/features/component_library/preset_library.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Bundled presets load and preserve their serialized node types',
    () async {
      await PresetLibrary.initialize();
      expect(PresetLibrary.presets, hasLength(5));
      for (final preset in PresetLibrary.presets) {
        expect(preset.nodes, isNotEmpty, reason: preset.name);
        final restored = SubCircuitDefinition.fromMap(preset.toMap());
        expect(
          restored.nodes.map((node) => node.runtimeType),
          preset.nodes.map((node) => node.runtimeType),
        );
        expect(restored.wires.length, preset.wires.length);
        expect(
          restored.effectivePinPlacements.keys,
          unorderedEquals(preset.effectivePinPlacements.keys),
        );
      }
    },
  );
}
