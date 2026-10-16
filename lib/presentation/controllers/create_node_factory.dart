import 'package:digital_logic_sim_2/presentation/tools/editor_tools.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/clock_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/display_nodes.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/gate_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/io_nodes.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/logic_probe_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/rgb_led_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/waveform_node.dart';
import 'package:digital_logic_sim_2/domain/entities/pin.dart';
import 'package:flutter/material.dart';

import 'package:digital_logic_sim_2/domain/entities/circuit_node.dart';

class CreateNodeFactory {
  CircuitNode create(EditorTool tool, Offset position) {
    final id = UniqueKey().toString();

    return switch (tool) {
      EditorTool.input => _createInput(id, position),
      EditorTool.output => _createOutput(id, position),
      //
      EditorTool.and => _createGate(id, Gate.and, position),
      EditorTool.or => _createGate(id, Gate.or, position),
      EditorTool.not => _createGate(id, Gate.not, position),
      EditorTool.nand => _createGate(id, Gate.nand, position),
      EditorTool.nor => _createGate(id, Gate.nor, position),
      EditorTool.xor => _createGate(id, Gate.xor, position),
      //
      EditorTool.segmentDisplay => _createSegmentDisplay(id, position),
      EditorTool.clock => _createClock(id, position),
      EditorTool.waveform => _createWaveform(id, position),
      EditorTool.rgbLed => _createRGBLED(id, position),
      EditorTool.logicProbe => _createLogicProbe(id, position),
      _ => throw UnimplementedError(
        'CreateNodeFactory.create() cannot handle $tool',
      ),
    };
  }

  InputNode _createInput(String id, Offset position) {
    return InputNode(
      id: id,
      position: position,
      inputPins: const [],
      outputPins: [
        Pin(
          id: 'out',
          nodeId: id,
          isInput: false,
          localPosition: const Offset(112, 32),
        ),
      ],
    );
  }

  OutputNode _createOutput(String id, Offset position) {
    return OutputNode(
      id: id,
      position: position,
      inputPins: [
        Pin(
          id: 'in',
          nodeId: id,
          isInput: true,
          localPosition: const Offset(0, 32),
        ),
      ],
      outputPins: const [],
    );
  }

  CircuitNode _createGate(String id, Gate type, Offset position) {
    switch (type) {
      case Gate.not:
        return GateNode(
          id: id,
          type: type,
          position: position,
          inputPins: [
            Pin(
              id: 'in',
              nodeId: id,
              isInput: true,
              localPosition: const Offset(0, 32),
            ),
          ],
          outputPins: [
            Pin(
              id: 'out',
              nodeId: id,
              isInput: false,
              localPosition: const Offset(112, 32),
            ),
          ],
        );

      default:
        return GateNode(
          id: id,
          type: type,
          position: position,
          inputPins: [
            Pin(
              id: 'a',
              nodeId: id,
              isInput: true,
              localPosition: const Offset(0, 16),
            ),
            Pin(
              id: 'b',
              nodeId: id,
              isInput: true,
              localPosition: const Offset(0, 48),
            ),
          ],
          outputPins: [
            Pin(
              id: 'out',
              nodeId: id,
              isInput: false,
              localPosition: const Offset(112, 32),
            ),
          ],
        );
    }
  }

  CircuitNode _createSegmentDisplay(String id, Offset position) {
    final inputPins = List.generate(7, (i) {
      return Pin(
        id: 'seg_$i',
        nodeId: id,
        isInput: true,
        localPosition: Offset(0, 16.0 + i * 16.0),
      );
    });

    return SegmentDisplayNode(
      id: id,
      position: position,
      inputPins: inputPins,
      outputPins: const [],
    );
  }

  CircuitNode _createClock(String id, Offset position) {
    return ClockNode(
      id: id,
      position: position,
      inputPins: const [],
      outputPins: [
        Pin(
          id: 'out',
          nodeId: id,
          isInput: false,
          localPosition: const Offset(112, 32),
        ),
      ],
    );
  }

  CircuitNode _createWaveform(String id, Offset position) {
    final inputPins = List.generate(4, (i) {
      return Pin(
        id: 'in_$i',
        nodeId: id,
        isInput: true,
        localPosition: Offset(0, 48.0 + i * 32.0),
      );
    });

    return WaveformNode(
      id: id,
      position: position,
      inputPins: inputPins,
      outputPins: const [],
    );
  }

  CircuitNode _createRGBLED(String id, Offset position) {
    final inputPins = [
      Pin(
        id: 'r',
        nodeId: id,
        isInput: true,
        localPosition: const Offset(0, 16),
      ),
      Pin(
        id: 'g',
        nodeId: id,
        isInput: true,
        localPosition: const Offset(0, 48),
      ),
      Pin(
        id: 'b',
        nodeId: id,
        isInput: true,
        localPosition: const Offset(0, 80),
      ),
    ];
    return RGBLEDNode(
      id: id,
      position: position,
      inputPins: inputPins,
      outputPins: const [],
    );
  }

  CircuitNode _createLogicProbe(String id, Offset position) {
    return LogicProbeNode(
      id: id,
      position: position,
      inputPins: [
        Pin(
          id: 'in',
          nodeId: id,
          isInput: true,
          localPosition: const Offset(0, 32),
        ),
      ],
      outputPins: const [],
    );
  }
}
