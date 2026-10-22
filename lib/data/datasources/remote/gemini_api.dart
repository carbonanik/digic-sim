import 'dart:convert';
import 'package:digital_logic_sim_2/domain/services/circuit_generator.dart';
import 'package:digital_logic_sim_2/domain/entities/pin_layout.dart';
import 'package:http/http.dart' as http;
import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';

/// Calls the Gemini API and returns a JSON string representing a logic circuit
/// that matches the [prompt] description.
class GeminiService implements CircuitGenerator {
  final http.Client _client;

  GeminiService({required http.Client client}) : _client = client;
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';

  static const _systemPrompt = '''
You are an expert digital logic circuit designer. The user will describe a logic circuit in natural language.
Your job is to produce a logically correct, readable circuit on a 16-unit grid.
Output ONLY a valid JSON object — no explanation, no markdown, no code fences.
Before responding, silently check the circuit logic, pin references, grid alignment, and every wire segment.

The JSON must conform exactly to this schema:

{
  "name": "<circuit name>",
  "nodes": [ <list of node objects> ],
  "wires": [ <list of wire objects> ],
  "color": 4281614400,
  "inputLabels": [ <list of string labels for input nodes, in order> ],
  "outputLabels": [ <list of string labels for output nodes, in order> ]
}

NODE TYPES and their required fields:

1. INPUT node (one per logical input):
{
  "id": "<unique string>",
  "type": "input",
  "position": {"dx": <number>, "dy": <number>},
  "inputPins": [],
  "outputPins": [{"id": "out", "nodeId": "<same id>", "isInput": false, "localPosition": {"dx": 112, "dy": 32}}],
  "value": false,
  "label": "<label string>"
}

2. OUTPUT node (one per logical output):
{
  "id": "<unique string>",
  "type": "output",
  "position": {"dx": <number>, "dy": <number>},
  "inputPins": [{"id": "in", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 32}}],
  "outputPins": [],
  "label": "<label string>"
}

3. AND gate:
{
  "id": "<unique string>",
  "type": "gate",
  "gateType": "and",
  "position": {"dx": <number>, "dy": <number>},
  "inputPins": [
    {"id": "a", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 16}},
    {"id": "b", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 32}}
  ],
  "outputPins": [{"id": "out", "nodeId": "<same id>", "isInput": false, "localPosition": {"dx": 112, "dy": 32}}]
}

4. OR gate — same as AND but "gateType": "or"
5. NAND gate — same as AND but "gateType": "nand"
6. NOR gate — same as AND but "gateType": "nor"
7. XOR gate — same as AND but "gateType": "xor"

8. NOT gate (single input):
{
  "id": "<unique string>",
  "type": "gate",
  "gateType": "not",
  "position": {"dx": <number>, "dy": <number>},
  "inputPins": [
    {"id": "in", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 32}}
  ],
  "outputPins": [{"id": "out", "nodeId": "<same id>", "isInput": false, "localPosition": {"dx": 112, "dy": 32}}]
}

9. SEGMENT DISPLAY (shows 7-segment output):
{
  "id": "<unique string>",
  "type": "segment_display",
  "position": {"dx": <number>, "dy": <number>},
  "inputPins": [
    {"id": "seg_0", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 16}},
    {"id": "seg_1", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 32}},
    {"id": "seg_2", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 48}},
    {"id": "seg_3", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 64}},
    {"id": "seg_4", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 80}},
    {"id": "seg_5", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 96}},
    {"id": "seg_6", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 112}}
  ],
  "outputPins": []
}

10. CLOCK (generates periodic high/low signal):
{
  "id": "<unique string>",
  "type": "clock",
  "position": {"dx": <number>, "dy": <number>},
  "inputPins": [],
  "outputPins": [{"id": "out", "nodeId": "<same id>", "isInput": false, "localPosition": {"dx": 112, "dy": 32}}],
  "value": false,
  "frequency": 1.0
}

11. WAVEFORM (oscilloscope display with 4 signal inputs):
{
  "id": "<unique string>",
  "type": "waveform",
  "position": {"dx": <number>, "dy": <number>},
  "inputPins": [
    {"id": "in_0", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 48}},
    {"id": "in_1", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 64}},
    {"id": "in_2", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 80}},
    {"id": "in_3", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 96}}
  ],
  "outputPins": []
}

12. RGB LED (emits colored light based on R, G, B inputs):
{
  "id": "<unique string>",
  "type": "rgb_led",
  "position": {"dx": <number>, "dy": <number>},
  "inputPins": [
    {"id": "r", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 16}},
    {"id": "g", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 32}},
    {"id": "b", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 48}}
  ],
  "outputPins": []
}

COORDINATE AND PIN RULES (REQUIRED):
- The grid step is exactly 16 units. Every node position, pin localPosition, and wire waypoint coordinate must be an integer multiple of 16: 0, 16, 32, 48, 64, 80, 96, 112, ... . Never use 100 or other off-grid coordinates.
- A node's position is the absolute top-left corner of its body. A pin's localPosition is relative to that corner, not an absolute canvas coordinate.
- Therefore an absolute pin position is node.position + pin.localPosition. Use this sum when routing wires.
- Adjacent pins on the same edge must be 16 units apart. Use the pin IDs and local positions in the built-in examples exactly; never invent off-grid offsets to make a connection fit.
- For existing composed ICs, the component catalog below is authoritative: copy its exact pin IDs and local positions, including any intentional gaps or pins on the top/bottom. Do not rearrange existing IC pins or assume all ICs have the same size.
- inputLabels and outputLabels describe the circuit's input/output nodes in their array order. Keep these labels consistent with the nodes' label fields.

LAYOUT RULES:
- Place INPUT nodes in the LEFT column at x=96, starting at y=96, with 96 units between rows.
- Place OUTPUT nodes on the RIGHT at x=800 or a larger multiple of 16. Align each output with its driving signal where practical.
- Place gates in intermediate columns starting at x=320, with at least 160 units between columns and 96 units between rows. Increase these spacings in multiples of 16 to fit larger components and routing lanes.
- Standard input/output/clock/gate bodies are 112 by 64 units; segment displays are 80 by 128; RGB LEDs are 80 by 96; four-channel waveforms are 200 by 160. Composed IC sizes are listed in the catalog.
- Keep component bodies separate and leave at least 32 units of free space between them. Body sizes describe obstacles; they do not change the 16-unit rule for positions and pins.
- Arrange signals left-to-right by logic stage. Place related inputs and outputs in a stable, readable order. Avoid unnecessary gates, wire crossings, and long detours.

WIRE object (waypoints shown as an example; calculate them for each connection):
{
  "id": "<unique string>",
  "fromNodeId": "<id of source node>",
  "fromPinId": "<pin id of source output pin>",
  "toNodeId": "<id of destination node>",
  "toPinId": "<pin id of destination input pin>",
  "waypoints": [{"dx": 336, "dy": 128}, {"dx": 336, "dy": 192}]
}

ORTHOGONAL WIRING RULES (REQUIRED):
- Every wire connects one output pin to one input pin. Each input pin has at most ONE incoming wire. Fan-out from one output to multiple inputs uses a separate wire object for each destination.
- Route every wire as an orthogonal polyline: horizontal and vertical segments only, with 90-degree bends. Diagonal segments are forbidden.
- Waypoints are absolute canvas coordinates for bends, ordered from source to destination. Do not include the source or destination pin itself in waypoints.
- To validate a route, form [absolute source pin, ...waypoints, absolute destination pin]. For EVERY consecutive pair, either x must be equal or y must be equal. Remove duplicate consecutive points and redundant collinear bends.
- Use an empty waypoints array ONLY if both absolute pin endpoints share the same x or the same y and the direct segment is unobstructed. Otherwise supply explicit bend points; do not leave routing unspecified.
- For a normal left-to-right connection with different endpoint heights, choose a free grid column midX and use bends (midX, sourceY), (midX, targetY). All three segments, including the first and last, must be axis-aligned.
- Example: an input at (96,96) with local output (112,32) has absolute output (208,128). An output node at (480,160) with local input (0,32) has absolute input (480,192). Valid waypoints are [(336,128),(336,192)], yielding (208,128) -> (336,128) -> (336,192) -> (480,192).
- Leave and enter pins perpendicular to the edge of the component. Respect top/bottom IC pins and route those vertically at the endpoint.
- Route through free lanes on the 16-unit grid. Except for the short lead entering/leaving its own pin, keep wires outside component bodies with at least 16 units of clearance. Move nodes or add grid-aligned bends when a simple route would cross a body.
- Keep unrelated parallel routes at least 16 units apart. Minimize crossings; a geometric crossing does not create an electrical junction.

FINAL VALIDATION BEFORE OUTPUT:
- Check the requested logic, including every output, using the intended truth table or state transitions.
- All node and wire IDs are unique strings. Every pin's nodeId matches its owning node.
- Every wire references existing nodes and pins of the correct direction, and no input has multiple drivers.
- Every node position, pin localPosition, absolute pin endpoint, and waypoint is on the 16-unit grid.
- All adjacent built-in pins are 16 units apart; existing IC pin layouts exactly match the catalog.
- Every wire segment, including the source-to-first-bend and last-bend-to-destination segments, is horizontal or vertical.
- Output ONLY the final raw JSON object, with complete node and wire arrays and no comments or trailing commas.
''';

  @override
  String buildSystemPrompt({
    List<SubCircuitDefinition> availableComponents = const [],
  }) {
    final componentsSection = StringBuffer();
    if (availableComponents.isNotEmpty) {
      componentsSection.writeln(
        '\nAVAILABLE COMPOSED COMPONENTS (INTEGRATED CIRCUITS):',
      );
      componentsSection.writeln(
        'You can (and should) reuse these pre-designed composed components if they fit the design. To instantiate them, use "type": "composed" and specify their "definition": {"name": "<Component Name>"} with the exact pin IDs listed below.',
      );
      for (final def in availableComponents) {
        final infos = def.pinInfos;
        final layout = PinLayoutEngine.compute(
          pins: infos,
          placements: def.effectivePinPlacements,
        );
        final inputs = infos.where((pin) => pin.isInput).toList();
        final outputs = infos.where((pin) => !pin.isInput).toList();

        Map<String, dynamic> describePin(PinInfo pin, int index) {
          final position = layout.positionFor(pin.key)!;
          return {
            'id': '${pin.isInput ? 'in' : 'out'}_$index',
            'nodeId': '<same id>',
            'isInput': pin.isInput,
            'localPosition': {'dx': position.dx, 'dy': position.dy},
          };
        }

        final inputPins = [
          for (var i = 0; i < inputs.length; i++) describePin(inputs[i], i),
        ];
        final outputPins = [
          for (var i = 0; i < outputs.length; i++) describePin(outputs[i], i),
        ];
        componentsSection.writeln('\n- Component ${jsonEncode(def.name)}:');
        componentsSection.writeln(
          '  Body size: ${layout.size.width} by ${layout.size.height} units.',
        );
        componentsSection.writeln('  Inputs:');
        for (var i = 0; i < inputs.length; i++) {
          componentsSection.writeln(
            '    ${jsonEncode(inputPins[i])}, label: ${jsonEncode(inputs[i].label)}',
          );
        }
        componentsSection.writeln('  Outputs:');
        for (var i = 0; i < outputs.length; i++) {
          componentsSection.writeln(
            '    ${jsonEncode(outputPins[i])}, label: ${jsonEncode(outputs[i].label)}',
          );
        }
        componentsSection.writeln(
          '  Example JSON (copy pin geometry exactly):',
        );
        componentsSection.writeln(
          jsonEncode({
            'id': '<unique string>',
            'type': 'composed',
            'position': {'dx': 320, 'dy': 96},
            'inputPins': inputPins,
            'outputPins': outputPins,
            'definition': {'name': def.name},
          }),
        );
      }
    }
    return '$_systemPrompt\n$componentsSection';
  }

  /// Generates circuit JSON from [prompt] using the Gemini API.
  /// Returns the raw JSON string on success.
  /// Throws a [CircuitGenerationException] on failure.
  @override
  Future<String> generateCircuit({
    required String apiKey,
    required String prompt,
    List<SubCircuitDefinition> availableComponents = const [],
  }) async {
    final url = Uri.parse('$_baseUrl?key=$apiKey');

    final systemPrompt = buildSystemPrompt(
      availableComponents: availableComponents,
    );

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': '$systemPrompt\n\nUser request: $prompt'},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'topP': 0.8,
        'maxOutputTokens': 8192,
      },
    });

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      String message = 'HTTP ${response.statusCode}';
      try {
        final err = jsonDecode(response.body);
        message = err['error']?['message'] ?? message;
      } catch (_) {}
      throw CircuitGenerationException(message);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw const CircuitGenerationException(
        'No candidates returned from Gemini API.',
      );
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw const CircuitGenerationException('Empty response from Gemini API.');
    }

    String text = (parts[0]['text'] as String).trim();

    // Strip markdown code fences if the model adds them anyway
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
      text = text.replaceFirst(RegExp(r'\n?```$'), '');
      text = text.trim();
    }

    // Validate it's parseable JSON
    try {
      jsonDecode(text);
    } catch (e) {
      throw CircuitGenerationException('Invalid JSON in model response: $e');
    }

    return text;
  }
}
