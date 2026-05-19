import 'dart:ui';

class Wire {
  final String id;
  final String fromNodeId;
  final String fromPinId;
  final String toNodeId;
  final String toPinId;
  final List<Offset> waypoints;

  const Wire({
    required this.id,
    required this.fromNodeId,
    required this.fromPinId,
    required this.toNodeId,
    required this.toPinId,
    this.waypoints = const [],
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'fromNodeId': fromNodeId,
    'fromPinId': fromPinId,
    'toNodeId': toNodeId,
    'toPinId': toPinId,
    'waypoints': waypoints.map((w) => {'dx': w.dx, 'dy': w.dy}).toList(),
  };

  static Wire fromMap(Map<String, dynamic> map) => Wire(
    id: map['id'],
    fromNodeId: map['fromNodeId'],
    fromPinId: map['fromPinId'],
    toNodeId: map['toNodeId'],
    toPinId: map['toPinId'],
    waypoints: (map['waypoints'] as List? ?? [])
        .map(
          (w) =>
              Offset((w['dx'] as num).toDouble(), (w['dy'] as num).toDouble()),
        )
        .toList(),
  );

  Wire copyWith({List<Offset>? waypoints}) {
    return Wire(
      id: id,
      fromNodeId: fromNodeId,
      fromPinId: fromPinId,
      toNodeId: toNodeId,
      toPinId: toPinId,
      waypoints: waypoints ?? this.waypoints,
    );
  }

  List<Offset> getPathPoints(Offset start, Offset end) {
    return [start, ...waypoints, end];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wire && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
