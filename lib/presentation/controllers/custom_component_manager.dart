import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:digital_logic_sim_2/data/models/pin_layout.dart';
import 'package:digital_logic_sim_2/data/repositories/sqlite_custom_component_repository.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';
import 'package:digital_logic_sim_2/domain/repositories/custom_component_repository.dart';

class CustomComponentManager {
  final CustomComponentRepository _repository;
  static final List<SubCircuitDefinition> _globalCustomDefinitions = [];

  CustomComponentManager({CustomComponentRepository? repository})
      : _repository = repository ?? SqliteCustomComponentRepository();

  List<SubCircuitDefinition> get customDefinitions => _globalCustomDefinitions;

  static Future<void> initializeCustomDefinitions({
    CustomComponentRepository? repository,
  }) async {
    final repo = repository ?? SqliteCustomComponentRepository();
    final list = await repo.loadAll();
    _globalCustomDefinitions.clear();
    for (final def in list) {
      _globalCustomDefinitions.add(def);
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
      customDefinitions.add(definition);
      SubCircuitDefinition.register(definition);
      _repository.save(definition);
      return definition;
    } catch (e) {
      debugPrint('Error importing IC: $e');
      return null;
    }
  }

  void removeCustomDefinition(SubCircuitDefinition definition) {
    customDefinitions.remove(definition);
    SubCircuitDefinition.registry.remove(definition);
    _repository.delete(definition.id);
  }

  void saveCustomDefinition(SubCircuitDefinition definition) {
    customDefinitions.add(definition);
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
