import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/nodes/composed_node.dart';

class PresetLibrary {
  static List<SubCircuitDefinition> _cachedPresets = [];

  static List<SubCircuitDefinition> get presets => _cachedPresets;

  /// Loads all preset definitions from the assets/lib/preset directory.
  static Future<void> initialize() async {
    try {
      // Use AssetManifest to find all assets in the lib/preset/ directory.
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assetPaths = manifest
          .listAssets()
          .where(
            (path) => path.startsWith('lib/preset/') && path.endsWith('.json'),
          )
          .toList();

      final List<SubCircuitDefinition> loadedPresets = [];

      for (final path in assetPaths) {
        final jsonString = await rootBundle.loadString(path);
        final map = jsonDecode(jsonString);
        loadedPresets.add(SubCircuitDefinition.fromMap(map));
      }

      _cachedPresets = loadedPresets;
    } catch (e) {
      print('Error loading presets: $e');
    }
  }
}
