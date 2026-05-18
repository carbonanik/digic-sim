import 'dart:convert';
import 'package:http/http.dart' as http;

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
- All positions are absolute pixel coordinates. Use multiples of 32 for alignment (grid is 16px).
- Each input pin of a gate may only be connected by ONE wire.

OUTPUT RULES:
- Output ONLY the raw JSON object. No markdown, no explanation.
- Make sure all node "id" values are unique strings (e.g. "n1", "n2", "g1", "g2", "out1").
- Make sure every wire references valid node IDs and pin IDs that exist in the nodes list.
- Make sure all the position values are multiples of 16 (x & y).
''';

  /// Generates circuit JSON from [prompt] using the Gemini API.
  /// Returns the raw JSON string on success.
  /// Throws a [GeminiException] on failure.
  static Future<String> generateCircuit({
    required String apiKey,
    required String prompt,
  }) async {
    final url = Uri.parse('$_baseUrl?key=$apiKey');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': '$_systemPrompt\n\nUser request: $prompt'},
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
