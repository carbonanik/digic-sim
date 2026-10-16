import 'dart:convert';
import 'package:digital_logic_sim_2/domain/entities/circuit.dart';

class CircuitSerializer {
  static String serialize(Circuit circuit) {
    return jsonEncode({});
  }

  static Circuit deserialize(String jsonStr) {
    return Circuit(nodes: [], wires: []);
  }
}
