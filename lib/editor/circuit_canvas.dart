import 'package:digital_logic_sim_2/editor/circuit_painter.dart';
import 'package:flutter/material.dart';

import '../controllers/circuit_controller.dart';
import 'editor_tools.dart';
import 'hit_test.dart';

class CircuitCanvas extends StatefulWidget {
  final CircuitController controller;

  const CircuitCanvas({super.key, required this.controller});

  @override
  State<CircuitCanvas> createState() => _CircuitCanvasState();
}

class _CircuitCanvasState extends State<CircuitCanvas> {
  final TransformationController transformationController =
      TransformationController();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff020617),
      child: InteractiveViewer(
        transformationController: transformationController,
        minScale: 0.2,
        maxScale: 3,
        boundaryMargin: const EdgeInsets.all(2000),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final point = details.localPosition;
            final controller = widget.controller;

            final pinHit = HitTesting.findPinAt(controller.circuit, point);

            if (controller.selectedTool == EditorTool.wire) {
              if (pinHit != null) {
                if (controller.wireStart == null) {
                  controller.startWire(pinHit.node, pinHit.pin);
                } else {
                  controller.finishWire(pinHit.node, pinHit.pin);
                }
              } else {
                controller.cancelWire();
              }
              return;
            }

            if (pinHit != null) return;

            final nodeHit = HitTesting.findNodeAt(controller.circuit, point);

            if (nodeHit != null) {
              final localPoint = point - nodeHit.position;
              controller.handleNodeAction(nodeHit.id, localPoint);
              controller.selectNode(nodeHit.id);
              return;
            }

            if (controller.selectedTool == EditorTool.select) {
              final wireHit = HitTesting.findWireAt(controller.circuit, point);
              if (wireHit != null) {
                controller.selectWire(wireHit.id);
                return;
              }
              controller.selectNode(null);
            } else {
              controller.addGateFromTool(point);
            }
          },
          onPanUpdate: (details) {
            final controller = widget.controller;

            if (controller.selectedTool == EditorTool.select) {
              controller.moveSelectedNode(details.delta);
            }

            if (controller.selectedTool == EditorTool.wire &&
                controller.wireStart != null) {
              controller.updateTemporaryWire(details.localPosition);
            }
          },
          child: CustomPaint(
            size: const Size(3000, 2200),
            painter: CircuitPainter(
              circuit: widget.controller.circuit,
              selectedNodeId: widget.controller.selectedNodeId,
              selectedWireId: widget.controller.selectedWireId,
              wireStart: widget.controller.wireStart,
              temporaryWireEnd: widget.controller.temporaryWireEnd,
            ),
          ),
        ),
      ),
    );
  }
}
