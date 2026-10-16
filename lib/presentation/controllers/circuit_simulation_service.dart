import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:digital_logic_sim_2/domain/entities/circuit.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/clock_node.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/waveform_node.dart';
import 'package:digital_logic_sim_2/domain/services/circuit_simulator.dart';
import 'package:digital_logic_sim_2/simulation/logic_circuit_simulator.dart';

class CircuitSimulationService {
  final CircuitSimulator _simulator;
  Timer? _clockTimer;

  double simulationFps = 0;
  double averageSimulationMs = 0;
  int lastSimulationSteps = 0;
  bool lastSimulationStabilized = true;

  int _simulationFramesInWindow = 0;
  int _simulationMicrosInWindow = 0;
  DateTime _simulationWindowStartedAt = DateTime.now();

  CircuitSimulationService({CircuitSimulator? simulator})
      : _simulator = simulator ?? LogicCircuitSimulator();

  void dispose() {
    _clockTimer?.cancel();
    _clockTimer = null;
  }

  void simulate(Circuit circuit) {
    final result = _simulator.simulate(circuit);
    _simulationFramesInWindow++;
    _simulationMicrosInWindow += result.elapsed.inMicroseconds;
    lastSimulationSteps = result.steps;
    lastSimulationStabilized = result.stabilized;

    final now = DateTime.now();
    final windowElapsed = now.difference(_simulationWindowStartedAt);
    if (windowElapsed.inMilliseconds >= 500) {
      simulationFps =
          _simulationFramesInWindow * 1000 / windowElapsed.inMilliseconds;
      averageSimulationMs =
          _simulationMicrosInWindow / _simulationFramesInWindow / 1000;
      _simulationFramesInWindow = 0;
      _simulationMicrosInWindow = 0;
      _simulationWindowStartedAt = now;
    }
  }

  void updateClockTimer({
    required Circuit circuit,
    required VoidCallback onTick,
  }) {
    final hasClocks = circuit.nodes.any((n) => n is ClockNode);
    final hasWaveforms = circuit.nodes.any((n) => n is WaveformNode);

    if ((hasClocks || hasWaveforms) && _clockTimer == null) {
      _clockTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
        bool changed = false;
        final now = DateTime.now();
        for (final node in circuit.nodes) {
          if (node is ClockNode) {
            final periodMs = 1000 / (2 * node.frequency);
            if (now.difference(node.lastToggleTime).inMilliseconds >=
                periodMs) {
              node.value = !node.value;
              node.lastToggleTime = now;
              changed = true;
            }
          }
        }

        if (changed || hasWaveforms) {
          simulate(circuit);
          onTick();
        }
      });
    } else if (!hasClocks && !hasWaveforms && _clockTimer != null) {
      _clockTimer?.cancel();
      _clockTimer = null;
    }
  }
}
