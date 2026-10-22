import 'package:flutter/material.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/display_nodes.dart';

extension SegmentDisplayNodeRendering on SegmentDisplayNode {
  void paint(Canvas canvas, bool isSelected, {bool isHovered = false}) {
    final rect = RRect.fromRectAndRadius(this.rect, const Radius.circular(8));

    final fillPaint = Paint()..color = const Color(0xff0f172a);
    final borderPaint = Paint()
      ..color = isSelected
          ? const Color(0xfffacc15)
          : (isHovered ? const Color(0xff475569) : const Color(0xff334155))
      ..strokeWidth = isSelected ? 3 : (isHovered ? 2.5 : 2)
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rect, fillPaint);

    if (isHovered && !isSelected) {
      final hoverGlow = Paint()
        ..color = const Color(0xff475569).withOpacity(0.3)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawRRect(rect, hoverGlow);
    }

    canvas.drawRRect(rect, borderPaint);

    _drawSegments(canvas);
  }

  void _drawSegments(Canvas canvas) {
    // Segment layout:
    //    0
    //  5   1
    //    6
    //  4   2
    //    3

    final center = position + Offset(size.width / 2, size.height / 2);
    const segmentWidth = 30.0;
    const thickness = 6.0;
    const gap = 4.0;

    void drawSeg(int index, Offset offset, bool horizontal) {
      final paint = Paint()
        ..color = segments[index]
            ? const Color(0xffef4444)
            : const Color(0xff1e293b)
        ..style = PaintingStyle.fill;

      final segRect = horizontal
          ? Rect.fromCenter(
              center: center + offset,
              width: segmentWidth,
              height: thickness,
            )
          : Rect.fromCenter(
              center: center + offset,
              width: thickness,
              height: segmentWidth,
            );

      canvas.drawRRect(
        RRect.fromRectAndRadius(segRect, const Radius.circular(thickness / 2)),
        paint,
      );
    }

    // Positions relative to center
    drawSeg(0, const Offset(0, -segmentWidth - gap), true);
    drawSeg(
      1,
      const Offset(segmentWidth / 2 + gap / 2, -segmentWidth / 2 - gap / 2),
      false,
    );
    drawSeg(
      2,
      const Offset(segmentWidth / 2 + gap / 2, segmentWidth / 2 + gap / 2),
      false,
    );
    drawSeg(3, const Offset(0, segmentWidth + gap), true);
    drawSeg(
      4,
      const Offset(-segmentWidth / 2 - gap / 2, segmentWidth / 2 + gap / 2),
      false,
    );
    drawSeg(
      5,
      const Offset(-segmentWidth / 2 - gap / 2, -segmentWidth / 2 - gap / 2),
      false,
    );
    drawSeg(6, const Offset(0, 0), true);
  }
}
