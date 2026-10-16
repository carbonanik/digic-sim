import 'dart:ui';
import 'package:collection/collection.dart';

class PathFinder {
  static const double gridSize = 16.0;
  static const double cornerPenalty = 120.0;
  static const double overlapPenalty = 40.0;

  static List<Offset> findPath({
    required Offset start,
    required Offset end,
    List<Rect> obstacles = const [],
    Set<WireSegment> existingSegments = const {},
  }) {
    final snappedStart = _snap(start);
    final snappedEnd = _snap(end);

    if (snappedStart == snappedEnd) return [start, end];

    final pq = PriorityQueue<_Node>((a, b) => a.f.compareTo(b.f));
    final visited = <Offset, double>{};

    pq.add(_Node(snappedStart, 0, _heuristic(snappedStart, snappedEnd), null));
    visited[snappedStart] = 0;

    _Node? targetNode;
    int iterations = 0;
    const maxIterations = 5000;

    while (pq.isNotEmpty && iterations < maxIterations) {
      iterations++;
      final current = pq.removeFirst();

      if (current.pos == snappedEnd) {
        targetNode = current;
        break;
      }

      if (current.g > (visited[current.pos] ?? double.infinity)) continue;

      for (final neighbor in _getNeighbors(current.pos)) {
        if (_isBlocked(neighbor, obstacles) && neighbor != snappedEnd) continue;

        double stepCost = gridSize;

        // Corner penalty
        if (current.parent != null) {
          final dir1 = current.pos - current.parent!.pos;
          final dir2 = neighbor - current.pos;
          // Check if direction changed
          if ((dir1.dx - dir2.dx).abs() > 0.1 ||
              (dir1.dy - dir2.dy).abs() > 0.1) {
            stepCost += cornerPenalty;
          }
        }

        // Overlap penalty
        if (existingSegments.contains(WireSegment(current.pos, neighbor))) {
          stepCost += overlapPenalty;
        }

        final newG = current.g + stepCost;

        if (newG < (visited[neighbor] ?? double.infinity)) {
          visited[neighbor] = newG;
          final newNode = _Node(
            neighbor,
            newG,
            _heuristic(neighbor, snappedEnd),
            current,
          );
          pq.add(newNode);
        }
      }
    }

    if (targetNode == null) {
      // Fallback: simple orthogonal path
      return [start, Offset(end.dx, start.dy), end];
    }

    final path = <Offset>[];
    _Node? curr = targetNode;
    while (curr != null) {
      path.add(curr.pos);
      curr = curr.parent;
    }
    final reversedPath = path.reversed.toList();

    return _simplify(start, end, reversedPath);
  }

  static Offset _snap(Offset p) {
    return Offset(
      (p.dx / gridSize).roundToDouble() * gridSize,
      (p.dy / gridSize).roundToDouble() * gridSize,
    );
  }

  static double _heuristic(Offset a, Offset b) {
    return (a.dx - b.dx).abs() + (a.dy - b.dy).abs();
  }

  static List<Offset> _getNeighbors(Offset p) {
    return [
      Offset(p.dx + gridSize, p.dy),
      Offset(p.dx - gridSize, p.dy),
      Offset(p.dx, p.dy + gridSize),
      Offset(p.dx, p.dy - gridSize),
    ];
  }

  static bool _isBlocked(Offset p, List<Rect> obstacles) {
    for (final rect in obstacles) {
      // Inflate slightly less to allow pins on the edge
      if (rect.deflate(2).contains(p)) return true;
    }
    return false;
  }

  static List<Offset> _simplify(Offset start, Offset end, List<Offset> path) {
    if (path.length <= 2) return [start, end];

    final result = <Offset>[start];

    for (int i = 1; i < path.length - 1; i++) {
      final prev = path[i - 1];
      final curr = path[i];
      final next = path[i + 1];

      final isCollinear =
          ((prev.dx - curr.dx).abs() < 0.1 &&
              (curr.dx - next.dx).abs() < 0.1) ||
          ((prev.dy - curr.dy).abs() < 0.1 && (curr.dy - next.dy).abs() < 0.1);

      if (!isCollinear) {
        result.add(curr);
      }
    }

    result.add(end);
    return result;
  }
}

class _Node {
  final Offset pos;
  final double g;
  final double h;
  final _Node? parent;

  _Node(this.pos, this.g, this.h, this.parent);

  double get f => g + h;
}

class WireSegment {
  final Offset p1;
  final Offset p2;

  WireSegment(Offset a, Offset b)
    : p1 = a.dx < b.dx || (a.dx == b.dx && a.dy < b.dy) ? a : b,
      p2 = a.dx < b.dx || (a.dx == b.dx && a.dy < b.dy) ? b : a;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WireSegment &&
          runtimeType == other.runtimeType &&
          p1 == other.p1 &&
          p2 == other.p2;

  @override
  int get hashCode => p1.hashCode ^ p2.hashCode;
}
