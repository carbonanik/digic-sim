import 'package:digital_logic_sim_2/editor/circuit_painter.dart';
import 'package:digital_logic_sim_2/models/circuit_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/circuit_controller.dart';
import '../models/nodes/composed_node.dart';
import '../models/nodes/io_nodes.dart';
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
  bool _isSpacePressed = false;
  final FocusNode _focusNode = FocusNode();

  /// Converts a screen-space [point] to scene-space coordinates,
  /// accounting for the current pan and zoom of the InteractiveViewer.
  Offset _toScene(Offset point) {
    return MatrixUtils.transformPoint(
      Matrix4.inverted(transformationController.value),
      point,
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _focusNode.requestFocus(),
      cursor: _isSpacePressed
          ? SystemMouseCursors.grab
          : widget.controller.hoveredPin != null
          ? SystemMouseCursors.precise
          : SystemMouseCursors.basic,
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event.logicalKey == LogicalKeyboardKey.space) {
            setState(() {
              _isSpacePressed =
                  event is KeyDownEvent || event is KeyRepeatEvent;
            });
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: GridPainter(
                    transformationController: transformationController,
                  ),
                ),
              ),
            ),
            // ── GestureDetector + MouseRegion are both OUTSIDE InteractiveViewer ─
            // All pointer positions are transformed into scene space via _toScene().
            // Deltas (drag/pan) are divided by the current scale to convert them too.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: _isSpacePressed
                  ? null
                  : (details) {
                      final point = _toScene(details.localPosition);
                      final controller = widget.controller;

                      final pinHit = HitTesting.findPinAt(
                        controller.circuit,
                        point,
                      );

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

                      final nodeHit = HitTesting.findNodeAt(
                        controller.circuit,
                        point,
                      );

                      if (nodeHit != null) {
                        final localPoint = point - nodeHit.position;
                        controller.handleNodeAction(nodeHit.id, localPoint);
                        controller.selectNode(nodeHit.id);
                        return;
                      }

                      if (controller.selectedTool == EditorTool.select) {
                        final wireHit = HitTesting.findWireHitAt(
                          controller.circuit,
                          point,
                        );
                        if (wireHit != null) {
                          controller.selectWire(wireHit.wire.id);
                          return;
                        }
                        controller.selectNode(null);
                      } else {
                        controller.addGateFromTool(point);
                      }
                    },
              onDoubleTap: () {
                final pos = widget.controller.mousePosition;
                if (pos != null) {
                  final nodeHit = HitTesting.findNodeAt(
                    widget.controller.circuit,
                    pos,
                  );
                  if (nodeHit is ComposedNode) {
                    widget.controller.loadDefinition(nodeHit.definition);
                    return;
                  }

                  if (nodeHit is InputNode || nodeHit is OutputNode) {
                    _showLabelDialog(context, nodeHit!);
                    return;
                  }

                  final wireHit = HitTesting.findWireHitAt(
                    widget.controller.circuit,
                    pos,
                  );
                  if (wireHit != null) {
                    widget.controller.resetWirePath(wireHit.wire.id);
                    return;
                  }
                }
              },
              child: MouseRegion(
                onHover: (event) {
                  final controller = widget.controller;
                  final scenePoint = _toScene(event.localPosition);

                  final pinHit = HitTesting.findPinAt(
                    controller.circuit,
                    scenePoint,
                  );

                  CircuitNode? nodeHit;
                  if (pinHit == null) {
                    nodeHit = HitTesting.findNodeAt(
                      controller.circuit,
                      scenePoint,
                    );
                  }

                  controller.updateHoverState(
                    position: scenePoint,
                    pinHit: pinHit,
                    nodeId: pinHit == null ? nodeHit?.id : null,
                  );
                },
                onExit: (event) {
                  widget.controller.updateHoverState(
                    position: null,
                    pinHit: null,
                    nodeId: null,
                  );
                },
                child: InteractiveViewer(
                  transformationController: transformationController,
                  minScale: 0.2,
                  maxScale: 3,
                  boundaryMargin: const EdgeInsets.all(2000),
                  panEnabled: _isSpacePressed ? true : false,
                  onInteractionStart: (details) {
                    // Only handle single-finger pan (pointerCount == 1).
                    // Two-finger pinch-to-zoom is handled by InteractiveViewer itself.
                    if (details.pointerCount != 1) return;
                    if (_isSpacePressed) return;

                    final controller = widget.controller;
                    final point = _toScene(details.localFocalPoint);
                    // final point = details.localFocalPoint;
                    controller.resetDragAccumulator();

                    final pinHit = HitTesting.findPinAt(
                      controller.circuit,
                      point,
                    );

                    if (pinHit != null &&
                        controller.selectedTool == EditorTool.select) {
                      controller.startWire(pinHit.node, pinHit.pin);
                      return;
                    }

                    if (controller.selectedTool == EditorTool.select) {
                      final nodeHit = HitTesting.findNodeAt(
                        controller.circuit,
                        point,
                      );
                      if (nodeHit != null) {
                        if (!controller.selectedNodeIds.contains(nodeHit.id)) {
                          controller.selectNode(nodeHit.id);
                        }
                      } else {
                        final wireHit = HitTesting.findWireHitAt(
                          controller.circuit,
                          point,
                        );
                        if (wireHit != null) {
                          controller.startWireDrag(wireHit, point);
                        } else {
                          controller.startMarqueeSelection(point);
                        }
                      }
                    }
                  },
                  onInteractionUpdate: (details) {
                    if (details.pointerCount != 1) return;

                    if (_isSpacePressed) {
                      // Space-pan: translate the scene matrix directly.
                      final matrix = transformationController.value;
                      final scale = matrix.getMaxScaleOnAxis();
                      transformationController.value = matrix.clone()
                        ..translate(
                          details.focalPointDelta.dx / scale,
                          details.focalPointDelta.dy / scale,
                        );
                      return;
                    }

                    final controller = widget.controller;
                    final scenePos = _toScene(details.localFocalPoint);
                    final scale = transformationController.value
                        .getMaxScaleOnAxis();
                    final sceneDelta = details.focalPointDelta / scale;

                    if (controller.wireStart != null) {
                      controller.updateTemporaryWire(scenePos);
                      return;
                    }

                    if (controller.selectionRect != null) {
                      controller.updateMarqueeSelection(scenePos);
                      return;
                    }

                    if (controller.draggedWireHit != null) {
                      controller.updateWireDrag(scenePos);
                      return;
                    }

                    if (controller.selectedTool == EditorTool.select &&
                        controller.selectedNodeIds.isNotEmpty) {
                      controller.moveSelectedNodes(sceneDelta);
                    }

                    if (controller.selectedTool == EditorTool.wire &&
                        controller.wireStart != null) {
                      controller.updateTemporaryWire(scenePos);
                    }
                  },
                  onInteractionEnd: (details) {
                    if (_isSpacePressed) return;

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
                      return;
                    }

                    if (controller.draggedWireHit != null) {
                      controller.endWireDrag();
                      return;
                    }

                    if (controller.selectedNodeIds.isNotEmpty) {
                      controller.endNodeMove();
                    }
                  },
                  child: AnimatedBuilder(
                    animation: widget.controller,
                    builder: (context, _) => Stack(
                      children: [
                        RepaintBoundary(
                          child: CustomPaint(
                            size: const Size(200000, 200000),
                            painter: CircuitPainter(
                              circuit: widget.controller.circuit,
                              selectedNodeIds:
                                  widget.controller.selectedNodeIds,
                              selectedWireId: widget.controller.selectedWireId,
                              repaintCounter:
                                  widget.controller.circuitRepaintCounter,
                            ),
                          ),
                        ),
                        RepaintBoundary(
                          child: CustomPaint(
                            size: const Size(200000, 200000),
                            painter: OverlayPainter(
                              circuit: widget.controller.circuit,
                              wireStart: widget.controller.wireStart,
                              temporaryWireEnd:
                                  widget.controller.temporaryWireEnd,
                              selectionRect: widget.controller.selectionRect,
                              hoveredNodeId: widget.controller.hoveredNodeId,
                              hoveredPin: widget.controller.hoveredPin,
                              mousePosition: widget.controller.mousePosition,
                              selectedTool: widget.controller.selectedTool,
                              selectedCustomComponent:
                                  widget.controller.selectedCustomComponent,
                              repaintCounter:
                                  widget.controller.overlayRepaintCounter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLabelDialog(BuildContext context, CircuitNode node) {
    String currentLabel = '';
    if (node is InputNode) {
      currentLabel = node.label;
    } else if (node is OutputNode) {
      currentLabel = node.label;
    }

    final textController = TextEditingController(text: currentLabel);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff0f172a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xff1f2937)),
        ),
        title: Text('Edit ${node is InputNode ? 'Input' : 'Output'} Label'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter label...',
            filled: true,
            fillColor: const Color(0xff1e293b),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (value) {
            widget.controller.updateNodeLabel(node.id, value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.controller.updateNodeLabel(node.id, textController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff38bdf8),
              foregroundColor: const Color(0xff020617),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
