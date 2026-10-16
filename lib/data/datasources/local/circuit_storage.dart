import 'package:digital_logic_sim_2/domain/entities/circuit.dart';

class CircuitStorage {
  final Map<String, Circuit> _circuits = {};

  Future<void> save(String id, Circuit circuit) async {
    _circuits[id] = circuit;
  }

  Future<Circuit?> get(String id) async {
    return _circuits[id];
  }
}
