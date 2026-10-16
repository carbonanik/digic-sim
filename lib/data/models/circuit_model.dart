import 'package:digital_logic_sim_2/domain/entities/circuit.dart';

class CircuitModel {
  final String id;
  final Circuit circuit;

  CircuitModel({required this.id, required this.circuit});

  Map<String, dynamic> toMap() {
    return {'id': id};
  }

  factory CircuitModel.fromMap(Map<String, dynamic> map) {
    return CircuitModel(
      id: map['id'] ?? '',
      circuit: Circuit(nodes: [], wires: []),
    );
  }
}
