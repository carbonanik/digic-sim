class Wire {
  final String id;
  final String fromNodeId;
  final String fromPinId;
  final String toNodeId;
  final String toPinId;

  const Wire({
    required this.id,
    required this.fromNodeId,
    required this.fromPinId,
    required this.toNodeId,
    required this.toPinId,
  });
}
