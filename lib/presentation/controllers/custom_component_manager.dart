import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:digital_logic_sim_2/domain/entities/pin_layout.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';
import 'package:digital_logic_sim_2/domain/repositories/custom_component_repository.dart';

class CustomComponentManager {
  final CustomComponentRepository _repository;
  final List<SubCircuitDefinition> _definitions = [];

  CustomComponentManager({required CustomComponentRepository repository})
    : _repository = repository;

  List<SubCircuitDefinition> get customDefinitions =>
      List.unmodifiable(_definitions);

  Future<void> initialize() async {
    final list = await _repository.loadAll();
    _definitions.clear();
    for (final def in list) {
      _definitions.add(def);
      SubCircuitDefinition.register(def);
    }
  }

  String exportIC(SubCircuitDefinition definition) {
    return jsonEncode(definition.toMap());
  }

  SubCircuitDefinition? importIC(String json) {
    try {
      final map = jsonDecode(json);
      final definition = SubCircuitDefinition.fromMap(map);
      _definitions.add(definition);
      SubCircuitDefinition.register(definition);
      _repository.save(definition);
      return definition;
    } catch (e) {
      debugPrint('Error importing IC: $e');
      return null;
    }
  }

  void removeCustomDefinition(SubCircuitDefinition definition) {
    _definitions.remove(definition);
    SubCircuitDefinition.registry.remove(definition);
    _repository.delete(definition.id);
  }

  void saveCustomDefinition(SubCircuitDefinition definition) {
    _definitions.add(definition);
    SubCircuitDefinition.register(definition);
    _repository.save(definition);
  }

  void updatePinLayout(
    SubCircuitDefinition definition,
    Map<String, PinPlacement> newPlacements,
  ) {
    definition.pinPlacements = newPlacements;
    _repository.save(definition);
  }
}
