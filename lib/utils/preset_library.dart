import 'dart:convert';
import '../models/nodes/composed_node.dart';

class PresetLibrary {
  static List<SubCircuitDefinition> get presets => [
    SubCircuitDefinition.fromMap(jsonDecode(_dFlipFlopJson)),
    SubCircuitDefinition.fromMap(jsonDecode(_fullAdderJson)),
    SubCircuitDefinition.fromMap(jsonDecode(_mux2to1Json)),
    SubCircuitDefinition.fromMap(jsonDecode(_register4BitJson)),
  ];

  static const String _register4BitJson = '''
{
  "name": "4-Bit Register",
  "color": 4279513901,
  "nodes": [
    { "id": "clk", "type": "input", "position": { "dx": 50, "dy": 400 }, "outputPins": [ { "id": "out", "nodeId": "clk", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "rst", "type": "input", "position": { "dx": 50, "dy": 500 }, "outputPins": [ { "id": "out", "nodeId": "rst", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "d0", "type": "input", "position": { "dx": 50, "dy": 50 }, "outputPins": [ { "id": "out", "nodeId": "d0", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "d1", "type": "input", "position": { "dx": 50, "dy": 120 }, "outputPins": [ { "id": "out", "nodeId": "d1", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "d2", "type": "input", "position": { "dx": 50, "dy": 190 }, "outputPins": [ { "id": "out", "nodeId": "d2", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "d3", "type": "input", "position": { "dx": 50, "dy": 260 }, "outputPins": [ { "id": "out", "nodeId": "d3", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "reg0", "type": "composed", "position": { "dx": 300, "dy": 50 }, "definition": { "name": "D Flip-Flop", "nodes": [], "wires": [], "color": 4280166715 }, "inputPins": [ { "id": "d", "nodeId": "reg0", "isInput": true, "localPosition": { "dx": 0, "dy": 30 } }, { "id": "clk", "nodeId": "reg0", "isInput": true, "localPosition": { "dx": 0, "dy": 50 } } ], "outputPins": [ { "id": "q", "nodeId": "reg0", "isInput": false, "localPosition": { "dx": 160, "dy": 40 } } ] },
    { "id": "reg1", "type": "composed", "position": { "dx": 300, "dy": 150 }, "definition": { "name": "D Flip-Flop", "nodes": [], "wires": [], "color": 4280166715 }, "inputPins": [ { "id": "d", "nodeId": "reg1", "isInput": true, "localPosition": { "dx": 0, "dy": 30 } }, { "id": "clk", "nodeId": "reg1", "isInput": true, "localPosition": { "dx": 0, "dy": 50 } } ], "outputPins": [ { "id": "q", "nodeId": "reg1", "isInput": false, "localPosition": { "dx": 160, "dy": 40 } } ] },
    { "id": "reg2", "type": "composed", "position": { "dx": 300, "dy": 250 }, "definition": { "name": "D Flip-Flop", "nodes": [], "wires": [], "color": 4280166715 }, "inputPins": [ { "id": "d", "nodeId": "reg2", "isInput": true, "localPosition": { "dx": 0, "dy": 30 } }, { "id": "clk", "nodeId": "reg2", "isInput": true, "localPosition": { "dx": 0, "dy": 50 } } ], "outputPins": [ { "id": "q", "nodeId": "reg2", "isInput": false, "localPosition": { "dx": 160, "dy": 40 } } ] },
    { "id": "reg3", "type": "composed", "position": { "dx": 300, "dy": 350 }, "definition": { "name": "D Flip-Flop", "nodes": [], "wires": [], "color": 4280166715 }, "inputPins": [ { "id": "d", "nodeId": "reg3", "isInput": true, "localPosition": { "dx": 0, "dy": 30 } }, { "id": "clk", "nodeId": "reg3", "isInput": true, "localPosition": { "dx": 0, "dy": 50 } } ], "outputPins": [ { "id": "q", "nodeId": "reg3", "isInput": false, "localPosition": { "dx": 160, "dy": 40 } } ] },
    { "id": "out0", "type": "output", "position": { "dx": 600, "dy": 50 }, "inputPins": [ { "id": "in", "nodeId": "out0", "isInput": true, "localPosition": { "dx": 0, "dy": 32 } } ] },
    { "id": "out1", "type": "output", "position": { "dx": 600, "dy": 150 }, "inputPins": [ { "id": "in", "nodeId": "out1", "isInput": true, "localPosition": { "dx": 0, "dy": 32 } } ] },
    { "id": "out2", "type": "output", "position": { "dx": 600, "dy": 250 }, "inputPins": [ { "id": "in", "nodeId": "out2", "isInput": true, "localPosition": { "dx": 0, "dy": 32 } } ] },
    { "id": "out3", "type": "output", "position": { "dx": 600, "dy": 350 }, "inputPins": [ { "id": "in", "nodeId": "out3", "isInput": true, "localPosition": { "dx": 0, "dy": 32 } } ] }
  ],
  "wires": [
    { "id": "w1", "fromNodeId": "clk", "fromPinId": "out", "toNodeId": "reg0", "toPinId": "clk" },
    { "id": "w2", "fromNodeId": "clk", "fromPinId": "out", "toNodeId": "reg1", "toPinId": "clk" },
    { "id": "w3", "fromNodeId": "clk", "fromPinId": "out", "toNodeId": "reg2", "toPinId": "clk" },
    { "id": "w4", "fromNodeId": "clk", "fromPinId": "out", "toNodeId": "reg3", "toPinId": "clk" },
    { "id": "w5", "fromNodeId": "d0", "fromPinId": "out", "toNodeId": "reg0", "toPinId": "d" },
    { "id": "w6", "fromNodeId": "d1", "fromPinId": "out", "toNodeId": "reg1", "toPinId": "d" },
    { "id": "w7", "fromNodeId": "d2", "fromPinId": "out", "toNodeId": "reg2", "toPinId": "d" },
    { "id": "w8", "fromNodeId": "d3", "fromPinId": "out", "toNodeId": "reg3", "toPinId": "d" },
    { "id": "w9", "fromNodeId": "reg0", "fromPinId": "q", "toNodeId": "out0", "toPinId": "in" },
    { "id": "wa", "fromNodeId": "reg1", "fromPinId": "q", "toNodeId": "out1", "toPinId": "in" },
    { "id": "wb", "fromNodeId": "reg2", "fromPinId": "q", "toNodeId": "out2", "toPinId": "in" },
    { "id": "wc", "fromNodeId": "reg3", "fromPinId": "q", "toNodeId": "out3", "toPinId": "in" }
  ],
  "inputLabels": [ "D0", "D1", "D2", "D3", "CLK", "RST" ],
  "outputLabels": [ "Q0", "Q1", "Q2", "Q3" ]
}
''';

  static const String _fullAdderJson = '''
{
  "name": "Full Adder",
  "color": 4279513901,
  "nodes": [
    { "id": "in_a", "type": "input", "position": { "dx": 50, "dy": 50 }, "outputPins": [ { "id": "out", "nodeId": "in_a", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "in_b", "type": "input", "position": { "dx": 50, "dy": 150 }, "outputPins": [ { "id": "out", "nodeId": "in_b", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "in_c", "type": "input", "position": { "dx": 50, "dy": 250 }, "outputPins": [ { "id": "out", "nodeId": "in_c", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "xor1", "type": "gate", "gateType": "xor", "position": { "dx": 250, "dy": 50 }, "inputPins": [ { "id": "a", "nodeId": "xor1", "isInput": true, "localPosition": { "dx": 0, "dy": 16 } }, { "id": "b", "nodeId": "xor1", "isInput": true, "localPosition": { "dx": 0, "dy": 48 } } ], "outputPins": [ { "id": "out", "nodeId": "xor1", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "xor2", "type": "gate", "gateType": "xor", "position": { "dx": 450, "dy": 100 }, "inputPins": [ { "id": "a", "nodeId": "xor2", "isInput": true, "localPosition": { "dx": 0, "dy": 16 } }, { "id": "b", "nodeId": "xor2", "isInput": true, "localPosition": { "dx": 0, "dy": 48 } } ], "outputPins": [ { "id": "out", "nodeId": "xor2", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "and1", "type": "gate", "gateType": "and", "position": { "dx": 450, "dy": 250 }, "inputPins": [ { "id": "a", "nodeId": "and1", "isInput": true, "localPosition": { "dx": 0, "dy": 16 } }, { "id": "b", "nodeId": "and1", "isInput": true, "localPosition": { "dx": 0, "dy": 48 } } ], "outputPins": [ { "id": "out", "nodeId": "and1", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "and2", "type": "gate", "gateType": "and", "position": { "dx": 250, "dy": 200 }, "inputPins": [ { "id": "a", "nodeId": "and2", "isInput": true, "localPosition": { "dx": 0, "dy": 16 } }, { "id": "b", "nodeId": "and2", "isInput": true, "localPosition": { "dx": 0, "dy": 48 } } ], "outputPins": [ { "id": "out", "nodeId": "and2", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "or1", "type": "gate", "gateType": "or", "position": { "dx": 650, "dy": 220 }, "inputPins": [ { "id": "a", "nodeId": "or1", "isInput": true, "localPosition": { "dx": 0, "dy": 16 } }, { "id": "b", "nodeId": "or1", "isInput": true, "localPosition": { "dx": 0, "dy": 48 } } ], "outputPins": [ { "id": "out", "nodeId": "or1", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "out_s", "type": "output", "position": { "dx": 850, "dy": 100 }, "inputPins": [ { "id": "in", "nodeId": "out_s", "isInput": true, "localPosition": { "dx": 0, "dy": 32 } } ] },
    { "id": "out_c", "type": "output", "position": { "dx": 850, "dy": 220 }, "inputPins": [ { "id": "in", "nodeId": "out_c", "isInput": true, "localPosition": { "dx": 0, "dy": 32 } } ] }
  ],
  "wires": [
    { "id": "w1", "fromNodeId": "in_a", "fromPinId": "out", "toNodeId": "xor1", "toPinId": "a" },
    { "id": "w2", "fromNodeId": "in_b", "fromPinId": "out", "toNodeId": "xor1", "toPinId": "b" },
    { "id": "w3", "fromNodeId": "in_a", "fromPinId": "out", "toNodeId": "and2", "toPinId": "a" },
    { "id": "w4", "fromNodeId": "in_b", "fromPinId": "out", "toNodeId": "and2", "toPinId": "b" },
    { "id": "w5", "fromNodeId": "xor1", "fromPinId": "out", "toNodeId": "xor2", "toPinId": "a" },
    { "id": "w6", "fromNodeId": "in_c", "fromPinId": "out", "toNodeId": "xor2", "toPinId": "b" },
    { "id": "w7", "fromNodeId": "xor1", "fromPinId": "out", "toNodeId": "and1", "toPinId": "a" },
    { "id": "w8", "fromNodeId": "in_c", "fromPinId": "out", "toNodeId": "and1", "toPinId": "b" },
    { "id": "w9", "fromNodeId": "and1", "fromPinId": "out", "toNodeId": "or1", "toPinId": "a" },
    { "id": "w10", "fromNodeId": "and2", "fromPinId": "out", "toNodeId": "or1", "toPinId": "b" },
    { "id": "w11", "fromNodeId": "xor2", "fromPinId": "out", "toNodeId": "out_s", "toPinId": "in" },
    { "id": "w12", "fromNodeId": "or1", "fromPinId": "out", "toNodeId": "out_c", "toPinId": "in" }
  ],
  "inputLabels": [ "A", "B", "Cin" ],
  "outputLabels": [ "Sum", "Cout" ]
}
''';

  static const String _mux2to1Json = '''
{
  "name": "2-to-1 MUX",
  "color": 4280166715,
  "nodes": [
    { "id": "in_a", "type": "input", "position": { "dx": 50, "dy": 50 }, "outputPins": [ { "id": "out", "nodeId": "in_a", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "in_b", "type": "input", "position": { "dx": 50, "dy": 250 }, "outputPins": [ { "id": "out", "nodeId": "in_b", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "in_s", "type": "input", "position": { "dx": 50, "dy": 150 }, "outputPins": [ { "id": "out", "nodeId": "in_s", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "not_s", "type": "gate", "gateType": "not", "position": { "dx": 200, "dy": 150 }, "inputPins": [ { "id": "in", "nodeId": "not_s", "isInput": true, "localPosition": { "dx": 0, "dy": 32 } } ], "outputPins": [ { "id": "out", "nodeId": "not_s", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "and1", "type": "gate", "gateType": "and", "position": { "dx": 400, "dy": 80 }, "inputPins": [ { "id": "a", "nodeId": "and1", "isInput": true, "localPosition": { "dx": 0, "dy": 16 } }, { "id": "b", "nodeId": "and1", "isInput": true, "localPosition": { "dx": 0, "dy": 48 } } ], "outputPins": [ { "id": "out", "nodeId": "and1", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "and2", "type": "gate", "gateType": "and", "position": { "dx": 400, "dy": 220 }, "inputPins": [ { "id": "a", "nodeId": "and2", "isInput": true, "localPosition": { "dx": 0, "dy": 16 } }, { "id": "b", "nodeId": "and2", "isInput": true, "localPosition": { "dx": 0, "dy": 48 } } ], "outputPins": [ { "id": "out", "nodeId": "and2", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "or1", "type": "gate", "gateType": "or", "position": { "dx": 600, "dy": 150 }, "inputPins": [ { "id": "a", "nodeId": "or1", "isInput": true, "localPosition": { "dx": 0, "dy": 16 } }, { "id": "b", "nodeId": "or1", "isInput": true, "localPosition": { "dx": 0, "dy": 48 } } ], "outputPins": [ { "id": "out", "nodeId": "or1", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ] },
    { "id": "out_y", "type": "output", "position": { "dx": 800, "dy": 150 }, "inputPins": [ { "id": "in", "nodeId": "out_y", "isInput": true, "localPosition": { "dx": 0, "dy": 32 } } ] }
  ],
  "wires": [
    { "id": "w1", "fromNodeId": "in_a", "fromPinId": "out", "toNodeId": "and1", "toPinId": "a" },
    { "id": "w2", "fromNodeId": "not_s", "fromPinId": "out", "toNodeId": "and1", "toPinId": "b" },
    { "id": "w3", "fromNodeId": "in_s", "fromPinId": "out", "toNodeId": "not_s", "toPinId": "in" },
    { "id": "w4", "fromNodeId": "in_s", "fromPinId": "out", "toNodeId": "and2", "toPinId": "a" },
    { "id": "w5", "fromNodeId": "in_b", "fromPinId": "out", "toNodeId": "and2", "toPinId": "b" },
    { "id": "w6", "fromNodeId": "and1", "fromPinId": "out", "toNodeId": "or1", "toPinId": "a" },
    { "id": "w7", "fromNodeId": "and2", "fromPinId": "out", "toNodeId": "or1", "toPinId": "b" },
    { "id": "w8", "fromNodeId": "or1", "fromPinId": "out", "toNodeId": "out_y", "toPinId": "in" }
  ],
  "inputLabels": [ "A", "B", "Sel" ],
  "outputLabels": [ "Y" ]
}
''';

  static const String _dFlipFlopJson = '''
{
  "name": "D Flip-Flop",
  "nodes": [
    {
      "id": "in_d",
      "type": "input",
      "position": { "dx": 50, "dy": 100 },
      "inputPins": [],
      "outputPins": [
        { "id": "out", "nodeId": "in_d", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } }
      ]
    },
    {
      "id": "in_clk",
      "type": "input",
      "position": { "dx": 50, "dy": 250 },
      "inputPins": [],
      "outputPins": [
        { "id": "out", "nodeId": "in_clk", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } }
      ]
    },
    {
      "id": "not_clk",
      "type": "gate",
      "gateType": "not",
      "position": { "dx": 200, "dy": 250 },
      "inputPins": [ { "id": "in", "nodeId": "not_clk", "isInput": true, "localPosition": { "dx": 0, "dy": 32 } } ],
      "outputPins": [ { "id": "out", "nodeId": "not_clk", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ]
    },
    {
      "id": "not_d",
      "type": "gate",
      "gateType": "not",
      "position": { "dx": 200, "dy": 100 },
      "inputPins": [ { "id": "in", "nodeId": "not_d", "isInput": true, "localPosition": { "dx": 0, "dy": 32 } } ],
      "outputPins": [ { "id": "out", "nodeId": "not_d", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ]
    },
    {
      "id": "m1",
      "type": "gate",
      "gateType": "nand",
      "position": { "dx": 400, "dy": 50 },
      "inputPins": [
        { "id": "p0", "nodeId": "m1", "isInput": true, "localPosition": { "dx": 0, "dy": 16 } },
        { "id": "p1", "nodeId": "m1", "isInput": true, "localPosition": { "dx": 0, "dy": 48 } }
      ],
      "outputPins": [ { "id": "out", "nodeId": "m1", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ]
    },
    {
      "id": "m2",
      "type": "gate",
      "gateType": "nand",
      "position": { "dx": 400, "dy": 150 },
      "inputPins": [
        { "id": "p0", "nodeId": "m2", "isInput": true, "localPosition": { "dx": 0, "dy": 16 } },
        { "id": "p1", "nodeId": "m2", "isInput": true, "localPosition": { "dx": 0, "dy": 48 } }
      ],
      "outputPins": [ { "id": "out", "nodeId": "m2", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ]
    },
    {
      "id": "m3",
      "type": "gate",
      "gateType": "nand",
      "position": { "dx": 550, "dy": 50 },
      "inputPins": [
        { "id": "p0", "nodeId": "m3", "isInput": true, "localPosition": { "dx": 0, "dy": 16 } },
        { "id": "p1", "nodeId": "m3", "isInput": true, "localPosition": { "dx": 0, "dy": 48 } }
      ],
      "outputPins": [ { "id": "out", "nodeId": "m3", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ]
    },
    {
      "id": "m4",
      "type": "gate",
      "gateType": "nand",
      "position": { "dx": 550, "dy": 150 },
      "inputPins": [
        { "id": "p0", "nodeId": "m4", "isInput": true, "localPosition": { "dx": 0, "dy": 16 } },
        { "id": "p1", "nodeId": "m4", "isInput": true, "localPosition": { "dx": 0, "dy": 48 } }
      ],
      "outputPins": [ { "id": "out", "nodeId": "m4", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ]
    },
    {
      "id": "s1",
      "type": "gate",
      "gateType": "nand",
      "position": { "dx": 750, "dy": 50 },
      "inputPins": [
        { "id": "p0", "nodeId": "s1", "isInput": true, "localPosition": { "dx": 0, "dy": 16 } },
        { "id": "p1", "nodeId": "s1", "isInput": true, "localPosition": { "dx": 0, "dy": 48 } }
      ],
      "outputPins": [ { "id": "out", "nodeId": "s1", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ]
    },
    {
      "id": "s2",
      "type": "gate",
      "gateType": "nand",
      "position": { "dx": 750, "dy": 150 },
      "inputPins": [
        { "id": "p0", "nodeId": "s2", "isInput": true, "localPosition": { "dx": 0, "dy": 16 } },
        { "id": "p1", "nodeId": "s2", "isInput": true, "localPosition": { "dx": 0, "dy": 48 } }
      ],
      "outputPins": [ { "id": "out", "nodeId": "s2", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ]
    },
    {
      "id": "s3",
      "type": "gate",
      "gateType": "nand",
      "position": { "dx": 900, "dy": 50 },
      "inputPins": [
        { "id": "p0", "nodeId": "s3", "isInput": true, "localPosition": { "dx": 0, "dy": 16 } },
        { "id": "p1", "nodeId": "s3", "isInput": true, "localPosition": { "dx": 0, "dy": 48 } }
      ],
      "outputPins": [ { "id": "out", "nodeId": "s3", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ]
    },
    {
      "id": "s4",
      "type": "gate",
      "gateType": "nand",
      "position": { "dx": 900, "dy": 150 },
      "inputPins": [
        { "id": "p0", "nodeId": "s4", "isInput": true, "localPosition": { "dx": 0, "dy": 16 } },
        { "id": "p1", "nodeId": "s4", "isInput": true, "localPosition": { "dx": 0, "dy": 48 } }
      ],
      "outputPins": [ { "id": "out", "nodeId": "s4", "isInput": false, "localPosition": { "dx": 112, "dy": 32 } } ]
    },
    {
      "id": "out_q",
      "type": "output",
      "position": { "dx": 1100, "dy": 50 },
      "inputPins": [ { "id": "in", "nodeId": "out_q", "isInput": true, "localPosition": { "dx": 0, "dy": 32 } } ],
      "outputPins": []
    },
    {
      "id": "out_q_inv",
      "type": "output",
      "position": { "dx": 1100, "dy": 150 },
      "inputPins": [ { "id": "in", "nodeId": "out_q_inv", "isInput": true, "localPosition": { "dx": 0, "dy": 32 } } ],
      "outputPins": []
    }
  ],
  "wires": [
    { "id": "w1", "fromNodeId": "in_d", "fromPinId": "out", "toNodeId": "m1", "toPinId": "p0" },
    { "id": "w2", "fromNodeId": "in_d", "fromPinId": "out", "toNodeId": "not_d", "toPinId": "in" },
    { "id": "w3", "fromNodeId": "not_d", "fromPinId": "out", "toNodeId": "m2", "toPinId": "p0" },
    { "id": "w4", "fromNodeId": "in_clk", "fromPinId": "out", "toNodeId": "m1", "toPinId": "p1" },
    { "id": "w5", "fromNodeId": "in_clk", "fromPinId": "out", "toNodeId": "m2", "toPinId": "p1" },
    { "id": "w6", "fromNodeId": "in_clk", "fromPinId": "out", "toNodeId": "not_clk", "toPinId": "in" },
    { "id": "w7", "fromNodeId": "m1", "fromPinId": "out", "toNodeId": "m3", "toPinId": "p0" },
    { "id": "w8", "fromNodeId": "m2", "fromPinId": "out", "toNodeId": "m4", "toPinId": "p0" },
    { "id": "w9", "fromNodeId": "m3", "fromPinId": "out", "toNodeId": "m4", "toPinId": "p1" },
    { "id": "w10", "fromNodeId": "m4", "fromPinId": "out", "toNodeId": "m3", "toPinId": "p1" },
    { "id": "w11", "fromNodeId": "m3", "fromPinId": "out", "toNodeId": "s1", "toPinId": "p0" },
    { "id": "w12", "fromNodeId": "m4", "fromPinId": "out", "toNodeId": "s2", "toPinId": "p0" },
    { "id": "w13", "fromNodeId": "not_clk", "fromPinId": "out", "toNodeId": "s1", "toPinId": "p1" },
    { "id": "w14", "fromNodeId": "not_clk", "fromPinId": "out", "toNodeId": "s2", "toPinId": "p1" },
    { "id": "w15", "fromNodeId": "s1", "fromPinId": "out", "toNodeId": "s3", "toPinId": "p0" },
    { "id": "w16", "fromNodeId": "s2", "fromPinId": "out", "toNodeId": "s4", "toPinId": "p0" },
    { "id": "w17", "fromNodeId": "s3", "fromPinId": "out", "toNodeId": "s4", "toPinId": "p1" },
    { "id": "w18", "fromNodeId": "s4", "fromPinId": "out", "toNodeId": "s3", "toPinId": "p1" },
    { "id": "w19", "fromNodeId": "s3", "fromPinId": "out", "toNodeId": "out_q", "toPinId": "in" },
    { "id": "w20", "fromNodeId": "s4", "fromPinId": "out", "toNodeId": "out_q_inv", "toPinId": "in" }
  ],
  "color": 4280166715,
  "inputLabels": [ "D", "CLK" ],
  "outputLabels": [ "Q", "Q'" ]
}
''';
}
