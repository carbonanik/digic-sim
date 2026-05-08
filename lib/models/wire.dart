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

  Map<String, dynamic> toMap() => {
        'id': id,
        'fromNodeId': fromNodeId,
        'fromPinId': fromPinId,
        'toNodeId': toNodeId,
        'toPinId': toPinId,
      };

  static Wire fromMap(Map<String, dynamic> map) => Wire(
        id: map['id'],
        fromNodeId: map['fromNodeId'],
        fromPinId: map['fromPinId'],
        toNodeId: map['toNodeId'],
        toPinId: map['toPinId'],
      );
}
