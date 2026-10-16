import 'package:flutter/material.dart';

/// Which edge of the IC body a pin is attached to.
enum PinSide { left, right, top, bottom }

/// Where a single logical pin (identified by the id of the underlying
/// InputNode/OutputNode inside the sub-circuit definition) sits on the
/// IC's body. This is stored on [SubCircuitDefinition] so it's persisted
/// alongside the IC and survives re-loading from disk.
class PinPlacement {
  final String pinKey; // == InputNode.id / OutputNode.id inside the definition
  final PinSide side;
  final int order; // lower = earlier along the side (top->bottom, left->right)
  final int gapUnits; // number of extra empty slots inserted *before* this pin

  const PinPlacement({
    required this.pinKey,
    required this.side,
    required this.order,
    this.gapUnits = 0,
  });

  PinPlacement copyWith({PinSide? side, int? order, int? gapUnits}) {
    return PinPlacement(
      pinKey: pinKey,
      side: side ?? this.side,
      order: order ?? this.order,
      gapUnits: gapUnits ?? this.gapUnits,
    );
  }

  Map<String, dynamic> toMap() => {
    'pinKey': pinKey,
    'side': side.name,
    'order': order,
    'gapUnits': gapUnits,
  };

  factory PinPlacement.fromMap(Map<String, dynamic> map) {
    return PinPlacement(
      pinKey: map['pinKey'] as String,
      side: PinSide.values.firstWhere(
        (s) => s.name == map['side'],
        orElse: () => PinSide.left,
      ),
      order: map['order'] as int? ?? 0,
      gapUnits: map['gapUnits'] as int? ?? 0,
    );
  }
}

/// Lightweight description of a pin, independent of the runtime [Pin]
/// class, so the designer UI can work with it without touching the
/// simulator model.
class PinInfo {
  final String key;
  final String label;
  final bool isInput;

  const PinInfo({
    required this.key,
    required this.label,
    required this.isInput,
  });
}

class PlacedPin {
  final PinInfo info;
  final PinPlacement placement;
  final Offset localPosition; // relative to the node's top-left corner

  const PlacedPin(this.info, this.placement, this.localPosition);
}

class IcLayoutResult {
  final Size size;
  final List<PlacedPin> pins;

  const IcLayoutResult(this.size, this.pins);

  Offset? positionFor(String pinKey) {
    for (final p in pins) {
      if (p.info.key == pinKey) return p.localPosition;
    }
    return null;
  }
}

/// Pure geometry: given pins + where they're placed, works out the IC
/// body size and every pin's local (x, y) position. No Flutter widget
/// state here — safe to call from both the real ComposedNode and the
/// designer's live preview.
class PinLayoutEngine {
  static const double pinSpacing = 16.0;
  static const double edgeMargin = 32.0; // corner -> first pin
  static const double gapUnitSize = 16.0; // size of one "gap" slot
  static const double minWidth = 160.0;
  static const double minHeight = 80.0;

  static IcLayoutResult compute({
    required List<PinInfo> pins,
    required Map<String, PinPlacement> placements,
  }) {
    final bySide = <PinSide, List<MapEntry<PinInfo, PinPlacement>>>{
      for (final s in PinSide.values) s: [],
    };

    for (final pin in pins) {
      final placement =
          placements[pin.key] ??
          PinPlacement(
            pinKey: pin.key,
            side: pin.isInput ? PinSide.left : PinSide.right,
            order: 0,
          );
      bySide[placement.side]!.add(MapEntry(pin, placement));
    }

    for (final list in bySide.values) {
      list.sort((a, b) => a.value.order.compareTo(b.value.order));
    }

    double extentFor(List<MapEntry<PinInfo, PinPlacement>> list) {
      if (list.isEmpty) return 0;
      double total = edgeMargin * 2;
      for (int i = 0; i < list.length; i++) {
        if (i > 0) total += pinSpacing;
        total += list[i].value.gapUnits * gapUnitSize;
      }
      return total;
    }

    final leftList = bySide[PinSide.left]!;
    final rightList = bySide[PinSide.right]!;
    final topList = bySide[PinSide.top]!;
    final bottomList = bySide[PinSide.bottom]!;

    final height = [
      minHeight,
      extentFor(leftList),
      extentFor(rightList),
    ].reduce((a, b) => a > b ? a : b);

    final width = [
      minWidth,
      extentFor(topList),
      extentFor(bottomList),
    ].reduce((a, b) => a > b ? a : b);

    final size = Size(width, height);
    final placed = <PlacedPin>[];

    void layoutVertical(List<MapEntry<PinInfo, PinPlacement>> list, double x) {
      double y = edgeMargin;
      for (int i = 0; i < list.length; i++) {
        if (i > 0) y += pinSpacing;
        y += list[i].value.gapUnits * gapUnitSize;
        placed.add(PlacedPin(list[i].key, list[i].value, Offset(x, y)));
      }
    }

    void layoutHorizontal(
      List<MapEntry<PinInfo, PinPlacement>> list,
      double y,
    ) {
      double x = edgeMargin;
      for (int i = 0; i < list.length; i++) {
        if (i > 0) x += pinSpacing;
        x += list[i].value.gapUnits * gapUnitSize;
        placed.add(PlacedPin(list[i].key, list[i].value, Offset(x, y)));
      }
    }

    layoutVertical(leftList, 0);
    layoutVertical(rightList, width);
    layoutHorizontal(topList, 0);
    layoutHorizontal(bottomList, height);

    return IcLayoutResult(size, placed);
  }

  /// Default layout matching the app's original behaviour: all inputs on
  /// the left, all outputs on the right, in their natural order. Used to
  /// seed a definition the first time it's created, and to fill in any
  /// pin that doesn't have an explicit placement yet (e.g. a pin added
  /// after the IC was first designed).
  static Map<String, PinPlacement> defaultPlacements(List<PinInfo> pins) {
    final result = <String, PinPlacement>{};
    int inOrder = 0;
    int outOrder = 0;
    for (final pin in pins) {
      if (pin.isInput) {
        result[pin.key] = PinPlacement(
          pinKey: pin.key,
          side: PinSide.left,
          order: inOrder++,
        );
      } else {
        result[pin.key] = PinPlacement(
          pinKey: pin.key,
          side: PinSide.right,
          order: outOrder++,
        );
      }
    }
    return result;
  }
}
