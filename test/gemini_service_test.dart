import 'dart:convert';
import 'package:digital_logic_sim_2/domain/entities/nodes/composed_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/io_nodes.dart';
import 'package:digital_logic_sim_2/domain/entities/pin_layout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:digital_logic_sim_2/data/datasources/remote/gemini_api.dart';
import 'package:digital_logic_sim_2/domain/services/circuit_generator.dart';

void main() {
  test('Uses injected HTTP client and extracts fenced circuit JSON', () async {
    final client = MockClient((request) async {
      expect(
        request.url.path,
        '/v1beta/models/gemini-3-flash-preview:generateContent',
      );
      expect(request.url.queryParameters['key'], 'test-key');
      expect(request.headers['Content-Type'], 'application/json');
      expect(
        jsonDecode(request.body)['contents'][0]['parts'][0]['text'],
        contains('User request: adder'),
      );
      return http.Response(
        jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': '```json\n{"nodes":[],"wires":[]}\n```'},
                ],
              },
            },
          ],
        }),
        200,
      );
    });
    addTearDown(client.close);
    final result = await GeminiService(
      client: client,
    ).generateCircuit(apiKey: 'test-key', prompt: 'adder');
    expect(jsonDecode(result), {'nodes': [], 'wires': []});
  });

  test('Catalog uses real IC pin geometry and fallback labels', () {
    final client = MockClient((_) async => http.Response('', 200));
    addTearDown(client.close);
    final definition = SubCircuitDefinition(
      id: 'custom_layout',
      name: 'Custom "IC"',
      nodes: [
        InputNode(
          id: 'a',
          position: Offset.zero,
          inputPins: [],
          outputPins: [],
          label: 'A',
        ),
        InputNode(
          id: 'b',
          position: Offset.zero,
          inputPins: [],
          outputPins: [],
          label: 'B',
        ),
        OutputNode(
          id: 'out',
          position: Offset.zero,
          inputPins: [],
          outputPins: [],
          label: 'Result',
        ),
      ],
      wires: [],
      pinPlacements: {
        'a': const PinPlacement(
          pinKey: 'a',
          side: PinSide.top,
          order: 0,
          gapUnits: 1,
        ),
        'b': const PinPlacement(pinKey: 'b', side: PinSide.top, order: 1),
        'out': const PinPlacement(
          pinKey: 'out',
          side: PinSide.bottom,
          order: 0,
          gapUnits: 10,
        ),
      },
    );
    final prompt = GeminiService(
      client: client,
    ).buildSystemPrompt(availableComponents: [definition]);
    final example =
        jsonDecode(
              prompt
                  .split('Example JSON (copy pin geometry exactly):\n')
                  .last
                  .trim(),
            )
            as Map<String, dynamic>;
    expect(example['definition']['name'], 'Custom "IC"');
    expect(example['inputPins'], hasLength(2));
    expect(example['outputPins'], hasLength(1));
    expect(example['inputPins'][0]['localPosition'], {'dx': 48.0, 'dy': 0.0});
    expect(example['inputPins'][1]['localPosition'], {'dx': 64.0, 'dy': 0.0});
    expect(example['outputPins'][0]['localPosition'], {
      'dx': 192.0,
      'dy': 80.0,
    });
    expect(example['inputPins'][0]['id'], 'in_0');
    expect(example['outputPins'][0]['id'], 'out_0');
    expect(prompt, contains('Body size: 224.0 by 80.0 units.'));
    expect(prompt, contains('label: "Result"'));
  });

  test('Maps API errors to the domain exception', () async {
    final client = MockClient(
      (_) async => http.Response('{"error":{"message":"Invalid key"}}', 403),
    );
    addTearDown(client.close);
    await expectLater(
      GeminiService(
        client: client,
      ).generateCircuit(apiKey: 'bad', prompt: 'adder'),
      throwsA(
        isA<CircuitGenerationException>().having(
          (error) => error.message,
          'message',
          'Invalid key',
        ),
      ),
    );
  });
}
