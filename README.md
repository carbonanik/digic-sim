# digital_logic_sim_2

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

==============================================================
/// Optimize circuit painting
==============================================================

 The current lag will mostly come from repeated full-list scans and full-canvas repaints. For 1000
  nodes/components, optimize in this order.

 1. Add a node lookup map

  Right now each wire endpoint lookup scans every node:

  lib/editor/circuit_painter.dart:207

  final node = _findNode(wire.fromNodeId);

  That makes wire painting roughly O(wires * nodes). With 1000 nodes and many wires, this hurts.

  Create/cache:

  final Map<String, CircuitNode> nodeById;

  Pass it into CircuitPainter, HitTesting, and path recalculation. Then endpoint lookup becomes:

  final node = nodeById[wire.fromNodeId];

  This is probably the highest-value fix.

  2. Cache Paint objects

  lib/editor/circuit_painter.dart:125 creates new Paints inside every wire/node/pin loop. For 1000
  nodes, that is thousands of allocations per frame.

  Move stable paints to static finals:

  static final wirePaint = Paint()
    ..color = const Color(0xff38bdf8)
    ..strokeWidth = 3
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  Do the same for pin fill/border paints.

  3. Cull offscreen nodes and wires

  CircuitPainter.paint() currently draws everything:

  lib/editor/circuit_painter.dart:100

  _drawWires(canvas);
  _drawNodes(canvas);

  Instead, compute the visible scene rect from transformationController.value, pass it to the painter,
  and skip anything outside it:

  if (!visibleRect.overlaps(node.rect.inflate(32))) continue;

  For wires, cache each wire path bounds and skip when it does not overlap the visible rect.

  This matters a lot because 1000 components may exist, but usually only a subset is visible.

  4. Spatial index hit testing

  Hover currently scans all nodes on every mouse move:

  lib/editor/circuit_canvas.dart:210
  lib/editor/hit_test.dart:24

  Use a simple grid index keyed by cell coordinate, for example 128x128 or 256x256 scene cells:

  Map<Point<int>, List<CircuitNode>> nodesByCell;

  Then findNodeAt, findPinAt, and marquee selection only check nearby cells instead of all 1000 nodes.

  5. Split static circuit paint from dynamic overlay

  You already have separate CircuitPainter and OverlayPainter, which is good. But the AnimatedBuilder
  rebuilds both CustomPaint widgets on every controller notify:

  lib/editor/circuit_canvas.dart:369

  A better structure is to give each painter its own Listenable, or use two ValueNotifier<int>s:

  CustomPaint(
    painter: CircuitPainter(..., repaint: controller.circuitRepaint),
  )

  CustomPaint(
    painter: OverlayPainter(..., repaint: controller.overlayRepaint),
  )

  Then hover/temporary-wire movement repaints only overlay, not the full circuit.

  6. Avoid repainting full circuit during drag when possible

  moveSelectedNodes() calls notifyCircuitChanged() during movement:

  lib/controllers/circuit_controller.dart:635

  For smooth dragging, draw moved selected nodes and affected wires in overlay during drag, then commit
  positions and recalculate paths on drag end. That avoids repainting 1000 static nodes every pointer
  update.

  7. Cache paths, labels, and gate shapes

  Each wire creates a new Path every paint:

  lib/editor/circuit_painter.dart:164

  Each gate/node also rebuilds shapes and some nodes create TextPainters. Cache per-node/per-wire render
  data and invalidate only when:

  node moved
  node selected/hovered changed
  wire endpoints changed
  wire waypoints changed
  zoom threshold changes for label visibility

  8. Make pathfinding incremental

  _recalculatePaths() builds obstacles from all nodes and may run A* for many wires:

  lib/controllers/circuit_controller.dart:1135

  For 1000 nodes:

  final obstacles = circuit.nodes.map((n) => n.rect).toList();

  should be cached and rebuilt only when node geometry changes. Also convert onlyWireIds to a
  Set<String> before checking membership.

  Practical order I’d implement:

  1. nodeById cache.
  2. Separate circuit/overlay repaint listenables.
  3. Paint/path caching.
  4. Viewport culling.
  5. Spatial index for hit testing.
  6. Drag overlay optimization.

  Those changes should make 1000 nodes realistic. The first two alone should remove the worst avoidable
  lag.

  ============================================================
  Optimize logic simulator
  ============================================================

  • For this codebase, the bottleneck is not just logic evaluation. To simulate and edit thousands of
  components smoothly, optimize in this order:

  1. Keep circuit indexes instead of rebuilding them every tick

  Right now lib/simulator/logic_simulator.dart:12 rebuilds:

  - nodeMap
  - outputPinMap
  - input wire lookup
  - outgoing wire lookup

  on every simulate(circuit) call. For thousands of nodes, that becomes expensive, especially with
  clocks firing every 20ms.

  Add cached indexes to Circuit, for example:

  class Circuit {
    final List<CircuitNode> nodes;
    final List<Wire> wires;

    final Map<String, CircuitNode> nodesById = {};
    final Map<String, Pin> pinsByKey = {};
    final Map<String, Wire> inputWireByPin = {};
    final Map<String, List<Wire>> outgoingWiresByNode = {};

    bool topologyDirty = true;
  }

  Rebuild those only when nodes/wires are added, removed, or rewired. Do not rebuild them for simple
  signal changes.

  2. Make simulation truly incremental

  Your simulator starts every run with:

  Set<String> dirtyNodeIds = nodeMap.keys.toSet();

  That means every simulation initially evaluates the whole circuit. Instead, track the actual changed
  source nodes.

  For example:

  - input toggled: dirty set starts with that input node
  - clock toggled: dirty set starts with that clock node
  - new wire added: dirty set starts with destination node
  - full load/import: dirty set starts with all nodes

  A better API would be:

  LogicSimulator.simulate(circuit, initialDirtyNodeIds: {nodeId});

  Then downstream propagation stays event-driven.

  3. Stop allocating lists inside every node evaluation

  This part allocates on every dirty node:

  final previousOutputs = List<bool>.generate(...);
  final inputs = List<bool>.generate(...);
  node.evaluate(inputs);

  For thousands of gates per tick, those allocations create GC pressure.

  Options:

  - Change evaluate(List<bool> inputs) to evaluate() and let each node read inputPins directly.
  - Or pass a reusable scratch buffer.
  - For simple gates, compare output before/after without allocating previousOutputs.

  Example shape:

  final before = node.outputPins.isNotEmpty ? node.outputPins.first.value : false;
  node.evaluateFromPins();
  final changed = node.outputPins.isNotEmpty && node.outputPins.first.value != before;

  4. Flatten composed nodes

  lib/models/nodes/composed_node.dart:162 calls LogicSimulator.simulate(internalCircuit) every time the
  composed node evaluates. If many ICs exist, this creates nested simulations and repeated index builds.

  For scale, compile custom components into one flat graph when placed, or give every composed node its
  own cached internal simulator/index. Best long-term option: flatten subcircuits into primitive nodes
  during simulation, while keeping the UI node as a visual abstraction.

  5. Add spatial indexes for UI operations

  Painting and hit-testing currently do many linear scans:

  - lib/editor/circuit_painter.dart:224 scans all nodes for each wire endpoint.
  - lib/editor/hit_test.dart:46 scans every wire and uses firstWhere over nodes.
  - lib/editor/hit_test.dart:23 scans every node.

  For thousands of nodes, add:

  - nodesById for wire endpoint lookup
  - a grid/quadtree spatial index for visible nodes, pins, and wire segments
  - viewport culling in the painter so offscreen components are not drawn

  At minimum, pass a cached Map<String, CircuitNode> into CircuitPainter and HitTesting.

  6. Do not pathfind during paint

  lib/editor/circuit_painter.dart:307 calls PathFinder.findPath during painting. That is expensive and
  can rerun multiple times per frame.

  Move path calculation into controller state when the mouse position changes, cache the temporary path,
  and have the painter only draw cached points.

  7. Recalculate only affected wire paths

  _recalculatePaths() can walk all wires and all obstacles. For scale:

  - when moving one node, recalculate only wires connected to that node
  - keep a wiresByNodeId index
  - avoid onlyWireIds.contains(...) if it is a list; use Set<String>
  - avoid rebuilding obstacles = circuit.nodes.map((n) => n.rect).toList() repeatedly during drag unless
    node positions changed

  8. Batch UI notifications

  Clock timer calls this every 20ms:

  LogicSimulator.simulate(circuit);
  notifyCircuitChanged();

  That can force full repaint at 50 FPS. For thousands of components:

  - simulate at logic tick rate
  - repaint at display frame rate
  - only repaint if visible output values changed
  - separate “logic changed” from “layout/path changed”

  For example, clock ticks should usually not trigger wire path recalculation or full canvas
  invalidation.

  9. Add benchmarks before changing architecture

  Create benchmark tests for:

  - 1,000 gates chain
  - 10,000 gates chain
  - wide fanout circuit
  - clocked circuit with 1,000 downstream nodes
  - many wires with viewport panning

  Measure:

  - simulation time
  - allocations
  - frame time during pan/zoom
  - path recalculation time

  The biggest wins here will come from cached circuit indexes, dirty-source simulation, removing per-
  node allocations, and viewport/spatial indexing. Those changes should get you from “works for small
  circuits” to “handles thousands predictably.”

  ============================================================
  Wire better ux
  ============================================================

   For this app, I’d improve wires in this order:

  1. Add wire hover feedback
     HitTesting.findWireHitAt already detects nearby wire segments with a forgiving 10px threshold in lib/editor/hit_test.dart:47, but the UI only uses it after click/drag. Track
     hoveredWireId in CircuitController and draw hovered wires thicker or brighter. This makes “this wire is selectable/editable” visible.
  2. Show valid and invalid wire targets while dragging
     In lib/controllers/circuit_controller.dart:708, wires can only start from output pins, and lib/controllers/circuit_controller.dart:721 silently cancels on invalid targets or
     occupied input pins. Instead:
      - highlight valid input pins green
      - highlight invalid pins red
      - change the temporary wire color based on whether the current hover target is valid
      - show a short status message for “input already connected” instead of just cancelling
  3. Make deletion visible
     Delete/Backspace already works in lib/main.dart:62, but users may not discover it. When a wire is selected, show a small floating mini-toolbar near the selected segment
     with:
      - delete icon
      - reset route icon
      - maybe “disconnect” text in tooltip only
  4. Add right-click or long-press context menu
     On a wire:
      - Delete wire
      - Reset path
      - Insert bend point
      - Duplicate route style maybe later
  5. Make editing handles clearer
     Selected wires currently show waypoint circles only when wire.waypoints.isNotEmpty in lib/editor/circuit_painter.dart:134. But auto-routed wires with no waypoints still
     appear editable via segment drag. Draw subtle segment handles or a highlighted draggable segment on hover, even before waypoints exist.
  6. Support endpoint reconnection
     A very user-friendly pattern is: select wire, drag either endpoint to a different compatible pin. That is usually more intuitive than deleting and recreating a wire.
  7. Make wire editing undoable
     endWireDrag currently adds an empty CircuitAction with a comment saying undo is tricky in lib/controllers/circuit_controller.dart:331. Fixing this matters because wire
     editing is easy to mis-drag. Store old and new waypoint lists in CircuitAction.
  8. Let users start from input pins too
     Internally, keep wires output-to-input, but UX can allow dragging from either side. If the user starts on an input pin, finish on an output pin and reverse the connection in
     code. That removes a common “why didn’t it connect?” failure.

  Best first patch: add hoveredWireId, hovered/selected wire styling, valid/invalid target highlighting, and a selected-wire mini-toolbar with delete/reset. That would make
  adding, editing, and deleting feel much more intentional without changing the circuit data model.
