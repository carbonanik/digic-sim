import 'dart:ui';

import 'package:digital_logic_sim_2/domain/entities/circuit_node.dart';

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}

extension NodeListExtension on List<CircuitNode> {
  List<Rect> toObstacles({double padding = 16}) {
    return map((node) => node.rect.inflate(padding)).toList();
  }
}
