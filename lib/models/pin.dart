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
}
