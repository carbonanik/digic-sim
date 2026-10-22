import 'package:digital_logic_sim_2/domain/entities/pin_layout.dart';
import 'package:flutter/material.dart';

/// A visual designer for arranging an IC's pins: drag pins between the
/// four edges, drop between two pins to reorder, tap a pin's gap badge
/// to cycle how much empty space precedes it (for grouping, e.g.
/// "4 pins, gap, 4 pins"). Returns the finished placement map via
/// `Navigator.pop(context, result)`.
class IcPinLayoutDesigner extends StatefulWidget {
  final String icName;
  final Color icColor;
  final List<PinInfo> pins;
  final Map<String, PinPlacement> initialPlacements;

  const IcPinLayoutDesigner({
    super.key,
    required this.icName,
    required this.icColor,
    required this.pins,
    required this.initialPlacements,
  });

  static Future<Map<String, PinPlacement>?> show(
    BuildContext context, {
    required String icName,
    required Color icColor,
    required List<PinInfo> pins,
    required Map<String, PinPlacement> initialPlacements,
  }) {
    return showDialog<Map<String, PinPlacement>>(
      context: context,
      builder: (context) => IcPinLayoutDesigner(
        icName: icName,
        icColor: icColor,
        pins: pins,
        initialPlacements: initialPlacements,
      ),
    );
  }

  @override
  State<IcPinLayoutDesigner> createState() => _IcPinLayoutDesignerState();
}

class _IcPinLayoutDesignerState extends State<IcPinLayoutDesigner> {
  late Map<PinSide, List<PinPlacement>> _bySide;
  late Map<String, PinInfo> _infoByKey;

  @override
  void initState() {
    super.initState();
    _infoByKey = {for (final p in widget.pins) p.key: p};

    final defaults = PinLayoutEngine.defaultPlacements(widget.pins);
    final effective = {
      for (final p in widget.pins)
        p.key: widget.initialPlacements[p.key] ?? defaults[p.key]!,
    };

    _bySide = {for (final s in PinSide.values) s: []};
    for (final placement in effective.values) {
      _bySide[placement.side]!.add(placement);
    }
    for (final list in _bySide.values) {
      list.sort((a, b) => a.order.compareTo(b.order));
    }
  }

  Map<String, PinPlacement> get _placementsMap => {
    for (final list in _bySide.values)
      for (final p in list) p.pinKey: p,
  };

  IcLayoutResult get _layout =>
      PinLayoutEngine.compute(pins: widget.pins, placements: _placementsMap);

  void _renumber(PinSide side) {
    final list = _bySide[side]!;
    for (int i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(order: i);
    }
  }

  void _movePin(String pinKey, PinSide toSide, int toIndex) {
    setState(() {
      PinSide? fromSide;
      for (final entry in _bySide.entries) {
        if (entry.value.any((p) => p.pinKey == pinKey)) {
          fromSide = entry.key;
          break;
        }
      }
      if (fromSide == null) return;

      final fromList = _bySide[fromSide]!;
      final existingIndex = fromList.indexWhere((p) => p.pinKey == pinKey);
      final placement = fromList.removeAt(existingIndex);

      final toList = _bySide[toSide]!;
      var insertAt = toIndex.clamp(0, toList.length);
      // If moving within the same list and removing shifted indices, adjust.
      if (fromSide == toSide && existingIndex < insertAt) {
        insertAt -= 1;
        insertAt = insertAt.clamp(0, toList.length);
      }

      toList.insert(insertAt, placement.copyWith(side: toSide));

      _renumber(fromSide);
      if (fromSide != toSide) _renumber(toSide);
    });
  }

  void _cycleGap(String pinKey) {
    setState(() {
      for (final list in _bySide.values) {
        final index = list.indexWhere((p) => p.pinKey == pinKey);
        if (index != -1) {
          final current = list[index];
          final nextGap = (current.gapUnits + 1) % 3; // 0 -> 1 -> 2 -> 0
          list[index] = current.copyWith(gapUnits: nextGap);
          return;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xff0f172a),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xff1f2937)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.dashboard_customize_rounded,
                    color: Color(0xff38bdf8),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Pin Layout — ${widget.icName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Drag a pin to move it between sides or reorder it. '
                'Tap the gap badge on a pin to add spacing before it.',
                style: TextStyle(color: Color(0xff94a3b8), fontSize: 12),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  children: [
                    _sideRow(PinSide.top, horizontal: true),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _sideColumn(PinSide.left),
                          const SizedBox(width: 8),
                          Expanded(child: _preview()),
                          const SizedBox(width: 8),
                          _sideColumn(PinSide.right),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _sideRow(PinSide.bottom, horizontal: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _placementsMap),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff38bdf8),
                      foregroundColor: const Color(0xff020617),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Save Layout'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sideLabel(PinSide side) {
    final text = switch (side) {
      PinSide.top => 'TOP',
      PinSide.bottom => 'BOTTOM',
      PinSide.left => 'LEFT',
      PinSide.right => 'RIGHT',
    };
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xff64748b),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  Widget _sideRow(PinSide side, {required bool horizontal}) {
    final list = _bySide[side]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sideLabel(side),
        const SizedBox(height: 4),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xff111827),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xff1f2937)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _slotsFor(side, list)),
          ),
        ),
      ],
    );
  }

  Widget _sideColumn(PinSide side) {
    final list = _bySide[side]!;
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sideLabel(side),
          const SizedBox(height: 4),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xff111827),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xff1f2937)),
              ),
              child: SingleChildScrollView(
                child: Column(children: _slotsFor(side, list)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds [dropSlot, chip, dropSlot, chip, ..., dropSlot] so you can drop
  /// a pin either onto another pin's position (inserts before it) or into
  /// the trailing empty slot (appends to the end).
  List<Widget> _slotsFor(PinSide side, List<PinPlacement> list) {
    final widgets = <Widget>[];
    widgets.add(_dropSlot(side, 0));
    for (int i = 0; i < list.length; i++) {
      widgets.add(_pinChip(list[i]));
      widgets.add(_dropSlot(side, i + 1));
    }
    return widgets;
  }

  Widget _dropSlot(PinSide side, int index) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => _movePin(details.data, side, index),
      builder: (context, candidate, rejected) {
        final active = candidate.isNotEmpty;
        return Container(
          // width: active ? 20 : 8,
          width: side == PinSide.top || side == PinSide.bottom
              ? (active ? 20 : 8)
              : 60,
          height: side == PinSide.top || side == PinSide.bottom
              ? 100
              : (active ? 20 : 8),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: active ? const Color(0xff38bdf8).withOpacity(0.4) : null,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  Widget _pinChip(PinPlacement placement) {
    final info = _infoByKey[placement.pinKey]!;
    final color = info.isInput
        ? const Color(0xfff97316)
        : const Color(0xff22c55e);

    final chip = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xff1e293b),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            info.label.isEmpty ? info.key : info.label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          if (placement.gapUnits > 0) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _cycleGap(placement.pinKey),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xff38bdf8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'gap ${placement.gapUnits}',
                  style: const TextStyle(
                    color: Color(0xff38bdf8),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else
            GestureDetector(
              onTap: () => _cycleGap(placement.pinKey),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.add_box_outlined,
                  size: 14,
                  color: Colors.white24,
                ),
              ),
            ),
        ],
      ),
    );

    return Draggable<String>(
      data: placement.pinKey,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.85, child: chip),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: chip,
    );
  }

  Widget _preview() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff0b1120),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xff1f2937)),
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(280, 280),
          painter: _PreviewPainter(
            layout: _layout,
            icColor: widget.icColor,
            icName: widget.icName,
          ),
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final IcLayoutResult layout;
  final Color icColor;
  final String icName;

  _PreviewPainter({
    required this.layout,
    required this.icColor,
    required this.icName,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final bodySize = layout.size;
    final scale = ((canvasSize.width - 40) / bodySize.width).clamp(
      0.0,
      (canvasSize.height - 40) / bodySize.height,
    );
    final offset = Offset(
      (canvasSize.width - bodySize.width * scale) / 2,
      (canvasSize.height - bodySize.height * scale) / 2,
    );

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, bodySize.width, bodySize.height),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, Paint()..color = icColor);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xff475569)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final labelPainter = TextPainter(
      text: TextSpan(
        text: icName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout(maxWidth: bodySize.width - 16);
    labelPainter.paint(
      canvas,
      Offset(
        (bodySize.width - labelPainter.width) / 2,
        bodySize.height / 2 - 8,
      ),
    );

    for (final pin in layout.pins) {
      final color = pin.info.isInput
          ? const Color(0xfff97316)
          : const Color(0xff22c55e);
      canvas.drawCircle(pin.localPosition, 5, Paint()..color = color);
      canvas.drawCircle(
        pin.localPosition,
        5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter oldDelegate) => true;
}
