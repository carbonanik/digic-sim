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
            .map((w) => Offset(w['dx'] as double, w['dy'] as double))
            .toList(),
      );

  Wire copyWith({
    List<Offset>? waypoints,
  }) {
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
    if (waypoints.isNotEmpty) {
      return [start, ...waypoints, end];
    }

    const minExtension = 16.0;
    final List<Offset> points = [start];

    if (end.dx > start.dx + 2 * minExtension) {
      final midX = (start.dx + end.dx) / 2;
      points.add(Offset(midX, start.dy));
      points.add(Offset(midX, end.dy));
    } else {
      final midY = (start.dy + end.dy) / 2;
      final outX = start.dx + minExtension;
      final inX = end.dx - minExtension;

      points.add(Offset(outX, start.dy));
      points.add(Offset(outX, midY));
      points.add(Offset(inX, midY));
      points.add(Offset(inX, end.dy));
    }

    points.add(end);
    return points;
  }
}
