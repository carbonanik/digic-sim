import 'dart:convert';
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
