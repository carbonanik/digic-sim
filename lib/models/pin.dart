import 'package:flutter/material.dart';

class Pin {
  final String id;
  final String nodeId;
  final bool isInput;
  final Offset localPosition;
  bool value;

  Pin({
    required this.id,
    required this.nodeId,
    required this.isInput,
    required this.localPosition,
    this.value = false,
  });

  Pin clone(String newNodeId) {
    return Pin(
      id: id,
      nodeId: newNodeId,
      isInput: isInput,
      localPosition: localPosition,
      value: value,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nodeId': nodeId,
        'isInput': isInput,
        'localPosition': {'dx': localPosition.dx, 'dy': localPosition.dy},
        'value': value,
      };

  static Pin fromMap(Map<String, dynamic> map) => Pin(
        id: map['id'],
        nodeId: map['nodeId'],
        isInput: map['isInput'],
        localPosition: Offset(
          (map['localPosition']['dx'] as num).toDouble(),
          (map['localPosition']['dy'] as num).toDouble(),
        ),
        value: map['value'] ?? false,
      );
}
