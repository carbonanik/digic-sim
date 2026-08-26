import 'package:flutter/material.dart';

class Grid {
  final double size;

  Grid({this.size = 16});

  Offset snap(Offset offset) => Offset(
    (offset.dx / size).round() * size,
    (offset.dy / size).round() * size,
  );
}
