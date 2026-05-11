import 'dart:collection';
import 'package:flutter/material.dart';
import '../circuit_node.dart';
import '../pin.dart';

class WaveformNode extends CircuitNode {
  static const int maxHistory = 100;
  final List<ListQueue<bool>> histories;

  WaveformNode({
    required super.id,
    required super.position,
    required super.inputPins,
    required super.outputPins,
  }) : histories = List.generate(
         inputPins.length,
         (_) => ListQueue<bool>(maxHistory),
       ) {
    // Pre-fill with false
    for (var history in histories) {
      for (int i = 0; i < maxHistory; i++) {
        history.addLast(false);
      }
    }
  }

  @override
  Size get size => Size(200, 40.0 + inputPins.length * 30.0);

  @override
  void evaluate(List<bool> inputs) {
    for (int i = 0; i < histories.length; i++) {
      if (i < inputs.length) {
        histories[i].removeFirst();
        histories[i].addLast(inputs[i]);
      }
    }
  }

  @override
  void paint(Canvas canvas, bool isSelected, {bool isHovered = false}) {
    final rect = RRect.fromRectAndRadius(this.rect, const Radius.circular(12));

    final fillPaint = Paint()..color = const Color(0xff020617);
    final borderPaint = Paint()
      ..color = isSelected
          ? const Color(0xff38bdf8)
          : (isHovered ? const Color(0xff1f2937) : const Color(0xff0f172a))
      ..strokeWidth = isSelected ? 2 : 1
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rect, fillPaint);
    canvas.drawRRect(rect, borderPaint);

    // Draw header
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'LOGIC ANALYZER',
        style: TextStyle(
          color: const Color(0xff38bdf8).withOpacity(0.8),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position + const Offset(12, 10));

    // Draw waveforms
    for (int i = 0; i < histories.length; i++) {
      _drawWaveform(canvas, i);
    }
  }

  void _drawWaveform(Canvas canvas, int index) {
    final history = histories[index];
    final startY = position.dy + 35 + index * 30;
    final startX = position.dx + 40;
    final width = size.width - 52;
    final height = 20.0;
    final step = width / (maxHistory - 1);

    final bgPaint = Paint()
      ..color = const Color(0xff1e293b).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(startX, startY, width, height), bgPaint);

    final path = Path();
    bool first = true;

    int i = 0;
    bool? prevVal;
    for (final val in history) {
      final x = startX + i * step;
      final y = startY + (val ? 4 : height - 4);

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        if (prevVal != val) {
          path.lineTo(x, startY + (prevVal! ? 4 : height - 4));
        }
        path.lineTo(x, y);
      }
      prevVal = val;
      i++;
    }

    final wavePaint = Paint()
      ..color = const Color(0xff38bdf8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.square;

    canvas.drawPath(path, wavePaint);

    // Draw label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'CH$index',
        style: const TextStyle(
          color: Color(0xff4b5563),
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(canvas, Offset(position.dx + 12, startY + 5));
  }

  @override
  CircuitNode clone(String newId) {
    return WaveformNode(
      id: newId,
      position: position,
      inputPins: inputPins.map((p) => p.clone(newId)).toList(),
      outputPins: outputPins.map((p) => p.clone(newId)).toList(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {...super.toMap(), 'type': 'waveform'};
  }
}
