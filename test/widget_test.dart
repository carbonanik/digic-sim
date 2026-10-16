// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:digital_logic_sim_2/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LogicDesignerApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

//
final a = {
  "id": "4-Bit_Counter",
  "name": "4-Bit Counter",
  "nodes": [
    {
      "id": "clk_in",
      "position": {"dx": 50.0, "dy": 300.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "clk_in",
          "isInput": false,
          "localPosition": {"dx": 110.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "",
    },
    {
      "id": "reset_in",
      "position": {"dx": 50.0, "dy": 450.0},
      "inputPins": [],
      "outputPins": [
        {
          "id": "out",
          "nodeId": "reset_in",
          "isInput": false,
          "localPosition": {"dx": 110.0, "dy": 32.0},
          "value": false,
        },
      ],
      "type": "input",
      "value": false,
      "label": "",
    },
    {
      "id": "bit_0",
      "position": {"dx": 300.0, "dy": 100.0},
      "inputPins": [
        {
          "id": "in_0",
          "nodeId": "bit_0",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "in_1",
          "nodeId": "bit_0",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 48.0},
          "value": false,
        },
        {
          "id": "in_2",
          "nodeId": "bit_0",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 64.0},
          "value": false,
        },
      ],
      "outputPins": [
        {
          "id": "out_0",
          "nodeId": "bit_0",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "out_1",
          "nodeId": "bit_0",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 48.0},
          "value": false,
        },
      ],
      "type": "composed",
      "reference": "D_Flip-Flop",
    },
    {
      "id": "bit_1",
      "position": {"dx": 300.0, "dy": 250.0},
      "inputPins": [
        {
          "id": "in_0",
          "nodeId": "bit_1",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "in_1",
          "nodeId": "bit_1",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 48.0},
          "value": false,
        },
        {
          "id": "in_2",
          "nodeId": "bit_1",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 64.0},
          "value": false,
        },
      ],
      "outputPins": [
        {
          "id": "out_0",
          "nodeId": "bit_1",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "out_1",
          "nodeId": "bit_1",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 48.0},
          "value": false,
        },
      ],
      "type": "composed",
      "reference": "D_Flip-Flop",
    },
    {
      "id": "bit_2",
      "position": {"dx": 300.0, "dy": 400.0},
      "inputPins": [
        {
          "id": "in_0",
          "nodeId": "bit_2",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "in_1",
          "nodeId": "bit_2",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 48.0},
          "value": false,
        },
        {
          "id": "in_2",
          "nodeId": "bit_2",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 64.0},
          "value": false,
        },
      ],
      "outputPins": [
        {
          "id": "out_0",
          "nodeId": "bit_2",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "out_1",
          "nodeId": "bit_2",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 48.0},
          "value": false,
        },
      ],
      "type": "composed",
      "reference": "D_Flip-Flop",
    },
    {
      "id": "bit_3",
      "position": {"dx": 300.0, "dy": 550.0},
      "inputPins": [
        {
          "id": "in_0",
          "nodeId": "bit_3",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "in_1",
          "nodeId": "bit_3",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 48.0},
          "value": false,
        },
        {
          "id": "in_2",
          "nodeId": "bit_3",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 64.0},
          "value": false,
        },
      ],
      "outputPins": [
        {
          "id": "out_0",
          "nodeId": "bit_3",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 32.0},
          "value": false,
        },
        {
          "id": "out_1",
          "nodeId": "bit_3",
          "isInput": false,
          "localPosition": {"dx": 160.0, "dy": 48.0},
          "value": false,
        },
      ],
      "type": "composed",
      "reference": "D_Flip-Flop",
    },
    {
      "id": "out_node_3",
      "position": {"dx": 600.0, "dy": 100.0},
      "inputPins": [
        {
          "id": "in",
          "nodeId": "out_node_3",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
      ],
      "outputPins": [],
      "type": "output",
      "value": false,
      "label": "",
    },
    {
      "id": "out_node_2",
      "position": {"dx": 600.0, "dy": 250.0},
      "inputPins": [
        {
          "id": "in",
          "nodeId": "out_node_2",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
      ],
      "outputPins": [],
      "type": "output",
      "value": false,
      "label": "",
    },
    {
      "id": "out_node_1",
      "position": {"dx": 600.0, "dy": 400.0},
      "inputPins": [
        {
          "id": "in",
          "nodeId": "out_node_1",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
      ],
      "outputPins": [],
      "type": "output",
      "value": false,
      "label": "",
    },
    {
      "id": "out_node_0",
      "position": {"dx": 600.0, "dy": 550.0},
      "inputPins": [
        {
          "id": "in",
          "nodeId": "out_node_0",
          "isInput": true,
          "localPosition": {"dx": 0.0, "dy": 32.0},
          "value": false,
        },
      ],
      "outputPins": [],
      "type": "output",
      "value": false,
      "label": "",
    },
  ],
  "wires": [
    {
      "id": "wire_fb_0",
      "fromNodeId": "bit_0",
      "fromPinId": "out_1",
      "toNodeId": "bit_0",
      "toPinId": "in_0",
      "waypoints": [],
    },
    {
      "id": "wire_clk_0",
      "fromNodeId": "clk_in",
      "fromPinId": "out",
      "toNodeId": "bit_0",
      "toPinId": "in_1",
      "waypoints": [],
    },
    {
      "id": "wire_fb_1",
      "fromNodeId": "bit_1",
      "fromPinId": "out_1",
      "toNodeId": "bit_1",
      "toPinId": "in_0",
      "waypoints": [],
    },
    {
      "id": "wire_clk_1",
      "fromNodeId": "bit_0",
      "fromPinId": "out_0",
      "toNodeId": "bit_1",
      "toPinId": "in_1",
      "waypoints": [],
    },
    {
      "id": "wire_fb_2",
      "fromNodeId": "bit_2",
      "fromPinId": "out_1",
      "toNodeId": "bit_2",
      "toPinId": "in_0",
      "waypoints": [],
    },
    {
      "id": "wire_clk_2",
      "fromNodeId": "bit_1",
      "fromPinId": "out_0",
      "toNodeId": "bit_2",
      "toPinId": "in_1",
      "waypoints": [],
    },
    {
      "id": "wire_fb_3",
      "fromNodeId": "bit_3",
      "fromPinId": "out_1",
      "toNodeId": "bit_3",
      "toPinId": "in_0",
      "waypoints": [],
    },
    {
      "id": "wire_clk_3",
      "fromNodeId": "bit_2",
      "fromPinId": "out_0",
      "toNodeId": "bit_3",
      "toPinId": "in_1",
      "waypoints": [],
    },
    {
      "id": "wire_final_out_3",
      "fromNodeId": "bit_3",
      "fromPinId": "out_0",
      "toNodeId": "out_node_3",
      "toPinId": "in",
      "waypoints": [],
    },
    {
      "id": "wire_final_out_2",
      "fromNodeId": "bit_2",
      "fromPinId": "out_0",
      "toNodeId": "out_node_2",
      "toPinId": "in",
      "waypoints": [],
    },
    {
      "id": "wire_final_out_1",
      "fromNodeId": "bit_1",
      "fromPinId": "out_0",
      "toNodeId": "out_node_1",
      "toPinId": "in",
      "waypoints": [],
    },
    {
      "id": "wire_final_out_0",
      "fromNodeId": "bit_0",
      "fromPinId": "out_0",
      "toNodeId": "out_node_0",
      "toPinId": "in",
      "waypoints": [],
    },
    {
      "id": "wire_reset_0",
      "fromNodeId": "reset_in",
      "fromPinId": "out",
      "toNodeId": "bit_0",
      "toPinId": "in_2",
      "waypoints": [],
    },
    {
      "id": "wire_reset_1",
      "fromNodeId": "reset_in",
      "fromPinId": "out",
      "toNodeId": "bit_1",
      "toPinId": "in_2",
      "waypoints": [],
    },
    {
      "id": "wire_reset_2",
      "fromNodeId": "reset_in",
      "fromPinId": "out",
      "toNodeId": "bit_2",
      "toPinId": "in_2",
      "waypoints": [],
    },
    {
      "id": "wire_reset_3",
      "fromNodeId": "reset_in",
      "fromPinId": "out",
      "toNodeId": "bit_3",
      "toPinId": "in_2",
      "waypoints": [],
    },
  ],
  "color": 4278238420,
  "inputLabels": ["CLK", "RESET"],
  "outputLabels": ["Q3 (MSB)", "Q2", "Q1", "Q0 (LSB)"],
  "pinPlacements": [],
};
