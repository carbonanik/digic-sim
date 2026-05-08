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
        child: MouseRegion(
          cursor: widget.controller.hoveredPin != null
              ? SystemMouseCursors.precise
              : SystemMouseCursors.basic,
          onHover: (event) {
            final controller = widget.controller;
            final point = event.localPosition;
            controller.setMousePosition(point);

            final pinHit = HitTesting.findPinAt(controller.circuit, point);
            controller.setHoveredPin(pinHit);

            if (pinHit == null) {
              final nodeHit = HitTesting.findNodeAt(controller.circuit, point);
              controller.setHoveredNode(nodeHit?.id);
            } else {
              controller.setHoveredNode(null);
            }
          },
          onExit: (event) {
            widget.controller.setHoveredPin(null);
            widget.controller.setHoveredNode(null);
            widget.controller.setMousePosition(null);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              final point = details.localPosition;
              final controller = widget.controller;

              final pinHit = HitTesting.findPinAt(controller.circuit, point);

              // Context-aware wiring or Wire tool wiring
              if (controller.selectedTool == EditorTool.wire ||
                  (controller.selectedTool == EditorTool.select &&
                      pinHit != null)) {
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
                final wireHit = HitTesting.findWireAt(
                  controller.circuit,
                  point,
                );
                if (wireHit != null) {
                  controller.selectWire(wireHit.id);
                  return;
                }
                controller.selectNode(null);
              } else {
                controller.addGateFromTool(point);
              }
            },
            onPanStart: (details) {
              final controller = widget.controller;
              final point = details.localPosition;

              final pinHit = HitTesting.findPinAt(controller.circuit, point);

              if (pinHit != null &&
                  controller.selectedTool == EditorTool.select) {
                controller.startWire(pinHit.node, pinHit.pin);
                return;
              }

              if (controller.selectedTool == EditorTool.select) {
                final nodeHit = HitTesting.findNodeAt(controller.circuit, point);
                if (nodeHit != null) {
                  // If we click a node that's not selected, select it (clearing others unless shift)
                  // For now, let's just support single click select or drag already selected.
                  if (!controller.selectedNodeIds.contains(nodeHit.id)) {
                    controller.selectNode(nodeHit.id);
                  }
                  // We'll move all selected nodes
                } else {
                  // Clicked empty space
                  controller.startMarqueeSelection(point);
                }
              }
            },
            onPanUpdate: (details) {
              final controller = widget.controller;

              if (controller.wireStart != null) {
                controller.updateTemporaryWire(details.localPosition);
                return;
              }

              if (controller.selectionRect != null) {
                controller.updateMarqueeSelection(details.localPosition);
                return;
              }

              if (controller.selectedTool == EditorTool.select &&
                  controller.selectedNodeIds.isNotEmpty) {
                controller.moveSelectedNodes(details.delta);
              }

              if (controller.selectedTool == EditorTool.wire &&
                  controller.wireStart != null) {
                controller.updateTemporaryWire(details.localPosition);
              }
            },
            onPanEnd: (details) {
              final controller = widget.controller;

              if (controller.selectionRect != null) {
                controller.endMarqueeSelection();
                return;
              }

              if (controller.wireStart != null &&
                  controller.temporaryWireEnd != null) {
                final pinHit = HitTesting.findPinAt(
                  controller.circuit,
                  controller.temporaryWireEnd!,
                );
                if (pinHit != null) {
                  controller.finishWire(pinHit.node, pinHit.pin);
                } else {
                  controller.cancelWire();
                }
              }
            },
            child: CustomPaint(
              size: const Size(3000, 2200),
              painter: CircuitPainter(
                circuit: widget.controller.circuit,
                selectedNodeIds: widget.controller.selectedNodeIds,
                selectedWireId: widget.controller.selectedWireId,
                wireStart: widget.controller.wireStart,
                temporaryWireEnd: widget.controller.temporaryWireEnd,
                selectionRect: widget.controller.selectionRect,
                hoveredNodeId: widget.controller.hoveredNodeId,
                hoveredPin: widget.controller.hoveredPin,
                mousePosition: widget.controller.mousePosition,
                selectedTool: widget.controller.selectedTool,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
