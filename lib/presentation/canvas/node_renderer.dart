import 'package:flutter/material.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/clock_node.dart';
import 'renderers/clock_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';
import 'renderers/composed_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/display_nodes.dart';
import 'renderers/display_nodes.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/gate_node.dart';
import 'renderers/gate_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/io_nodes.dart';
import 'renderers/io_nodes.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/logic_probe_node.dart';
import 'renderers/logic_probe_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/rgb_led_node.dart';
import 'renderers/rgb_led_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/waveform_node.dart';
import 'renderers/waveform_node.dart';

/// Presentation owns drawing; circuit entities own state and evaluation.
extension CircuitNodeRendering on CircuitNode {
  void paint(Canvas canvas, bool isSelected, {bool isHovered = false}) {
    switch (this) {
      case ClockNode node:
        node.paint(canvas, isSelected, isHovered: isHovered);
      case ComposedNode node:
        node.paint(canvas, isSelected, isHovered: isHovered);
      case SegmentDisplayNode node:
        node.paint(canvas, isSelected, isHovered: isHovered);
      case GateNode node:
        node.paint(canvas, isSelected, isHovered: isHovered);
      case InputNode node:
        node.paint(canvas, isSelected, isHovered: isHovered);
      case OutputNode node:
        node.paint(canvas, isSelected, isHovered: isHovered);
      case LogicProbeNode node:
        node.paint(canvas, isSelected, isHovered: isHovered);
      case RGBLEDNode node:
        node.paint(canvas, isSelected, isHovered: isHovered);
      case WaveformNode node:
        node.paint(canvas, isSelected, isHovered: isHovered);
      default:
        throw UnsupportedError('No renderer for $runtimeType');
    }
  }
}
