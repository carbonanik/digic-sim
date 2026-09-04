import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/entities/nodes/composed_node.dart';

/// Calls the Gemini API and returns a JSON string representing a logic circuit
/// that matches the [prompt] description.
class GeminiService {
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';

  static const _systemPrompt = '''
You are an expert digital logic circuit designer. The user will describe a logic circuit in natural language.
Your job is to output ONLY a valid JSON object representing that circuit — no explanation, no markdown, no code fences.

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
    {"id": "b", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 48}}
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
    {"id": "in_1", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 80}},
    {"id": "in_2", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 112}},
    {"id": "in_3", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 144}}
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
    {"id": "g", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 48}},
    {"id": "b", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": 80}}
  ],
  "outputPins": []
}

WIRE object:
{
  "id": "<unique string>",
  "fromNodeId": "<id of source node>",
  "fromPinId": "<pin id of source output pin>",
  "toNodeId": "<id of destination node>",
  "toPinId": "<pin id of destination input pin>",
  "waypoints": []
}

LAYOUT RULES:
- Place INPUT nodes on the LEFT side, starting at dx=100, spacing dy by 96 between each.
- Place OUTPUT nodes on the RIGHT side at dx=800+, vertically centered.
- Place logic gates in the MIDDLE, spaced horizontally by ~160 and vertically by ~96.
- All positions are absolute pixel coordinates. Use multiples of 16 for alignment (grid is 16px).
- Each input pin of a gate may only be connected by ONE wire.

OUTPUT RULES:
- Output ONLY the raw JSON object. No markdown, no explanation.
- Make sure all node "id" values are unique strings (e.g. "n1", "n2", "g1", "g2", "out1").
- Make sure every wire references valid node IDs and pin IDs that exist in the nodes list.
''';

  static String buildSystemPrompt({
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
        componentsSection.writeln('\n- Component "${def.name}":');
        componentsSection.writeln('  Inputs:');
        for (int i = 0; i < def.inputLabels.length; i++) {
          componentsSection.writeln(
            '    Pin ID "in_$i" (Label: "${def.inputLabels[i]}"), localPosition: {"dx": 0, "dy": ${32 + i * 16}}',
          );
        }
        componentsSection.writeln('  Outputs:');
        for (int i = 0; i < def.outputLabels.length; i++) {
          componentsSection.writeln(
            '    Pin ID "out_$i" (Label: "${def.outputLabels[i]}"), localPosition: {"dx": 160, "dy": ${32 + i * 16}}',
          );
        }
        componentsSection.writeln('  Example JSON for "${def.name}":');
        componentsSection.writeln('  {');
        componentsSection.writeln('    "id": "<unique string>",');
        componentsSection.writeln('    "type": "composed",');
        componentsSection.writeln(
          '    "position": {"dx": <number>, "dy": <number>},',
        );
        final inPins = List.generate(
          def.inputLabels.length,
          (i) =>
              '      {"id": "in_$i", "nodeId": "<same id>", "isInput": true, "localPosition": {"dx": 0, "dy": ${32 + i * 16}}}',
        ).join(',\n');
        componentsSection.writeln('    "inputPins": [\n$inPins\n    ],');
        final outPins = List.generate(
          def.outputLabels.length,
          (i) =>
              '      {"id": "out_$i", "nodeId": "<same id>", "isInput": false, "localPosition": {"dx": 160, "dy": ${32 + i * 16}}}',
        ).join(',\n');
        componentsSection.writeln('    "outputPins": [\n$outPins\n    ],');
        componentsSection.writeln('    "definition": {"name": "${def.name}"}');
        componentsSection.writeln('  }');
      }
    }
    return '$_systemPrompt\n$componentsSection';
  }

  /// Generates circuit JSON from [prompt] using the Gemini API.
  /// Returns the raw JSON string on success.
  /// Throws a [GeminiException] on failure.
  static Future<String> generateCircuit({
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

    final response = await http.post(
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
      throw GeminiException(message);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw const GeminiException('No candidates returned from Gemini API.');
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw const GeminiException('Empty response from Gemini API.');
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
      throw GeminiException('Invalid JSON in model response: $e');
    }

    return text;
  }
}

class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);
  @override
  String toString() => 'GeminiException: $message';
}
