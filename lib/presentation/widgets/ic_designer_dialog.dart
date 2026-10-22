import 'package:flutter/material.dart';
import 'package:digital_logic_sim_2/domain/entities/pin_layout.dart';
import 'package:digital_logic_sim_2/domain/entities/nodes/io_nodes.dart';
import 'package:digital_logic_sim_2/presentation/controllers/circuit_controller.dart';
import 'package:digital_logic_sim_2/presentation/widgets/ic_pin_layout_designer.dart';

class IcDesignerDialog extends StatefulWidget {
  final CircuitController controller;

  const IcDesignerDialog({
    super.key,
    required this.controller,
  });

  static Future<void> show(BuildContext context, CircuitController controller) {
    return showDialog(
      context: context,
      builder: (context) => IcDesignerDialog(controller: controller),
    );
  }

  @override
  State<IcDesignerDialog> createState() => _IcDesignerDialogState();
}

class _IcDesignerDialogState extends State<IcDesignerDialog> {
  late final List<InputNode> inputNodes;
  late final List<OutputNode> outputNodes;

  late final TextEditingController nameController;
  late final List<TextEditingController> inputControllers;
  late final List<TextEditingController> outputControllers;

  Color selectedColor = const Color(0xff1e3a8a);
  Map<String, PinPlacement> pinPlacements = {};

  @override
  void initState() {
    super.initState();
    inputNodes = widget.controller.circuit.nodes.whereType<InputNode>().toList();
    outputNodes = widget.controller.circuit.nodes.whereType<OutputNode>().toList();

    nameController = TextEditingController();
    inputControllers = List.generate(
      inputNodes.length,
      (i) => TextEditingController(text: inputNodes[i].label),
    );
    outputControllers = List.generate(
      outputNodes.length,
      (i) => TextEditingController(text: outputNodes[i].label),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    for (final c in inputControllers) {
      c.dispose();
    }
    for (final c in outputControllers) {
      c.dispose();
    }
    super.dispose();
  }

  static const _headerStyle = TextStyle(
    color: Color(0xff94a3b8),
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xff1e293b),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xff0f172a),
      title: const Text('IC Designer'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('COMPONENT NAME', style: _headerStyle),
              TextField(
                controller: nameController,
                decoration: _inputDeco('e.g. Full Adder'),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              const Text('BODY COLOR', style: _headerStyle),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  const Color(0xff1e3a8a),
                  const Color(0xff581c87),
                  const Color(0xff701a75),
                  const Color(0xff14532d),
                  const Color(0xff7c2d12),
                  const Color(0xff0f172a),
                ]
                    .map(
                      (color) => GestureDetector(
                        onTap: () => setState(() => selectedColor = color),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColor == color
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                icon: const Icon(
                  Icons.dashboard_customize_rounded,
                  size: 16,
                ),
                label: const Text('Arrange Pins'),
                onPressed: () async {
                  final pins = [
                    for (int i = 0; i < inputNodes.length; i++)
                      PinInfo(
                        key: inputNodes[i].id,
                        label: inputControllers[i].text,
                        isInput: true,
                      ),
                    for (int i = 0; i < outputNodes.length; i++)
                      PinInfo(
                        key: outputNodes[i].id,
                        label: outputControllers[i].text,
                        isInput: false,
                      ),
                  ];
                  final result = await IcPinLayoutDesigner.show(
                    context,
                    icName: nameController.text.isEmpty
                        ? 'IC'
                        : nameController.text,
                    icColor: selectedColor,
                    pins: pins,
                    initialPlacements: pinPlacements,
                  );
                  if (result != null) {
                    setState(() => pinPlacements = result);
                  }
                },
              ),
              const SizedBox(height: 20),
              if (inputNodes.isNotEmpty) ...[
                const Text('INPUT LABELS', style: _headerStyle),
                const SizedBox(height: 8),
                ...List.generate(
                  inputNodes.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextField(
                      controller: inputControllers[i],
                      decoration: _inputDeco('Input ${i + 1} Label'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (outputNodes.isNotEmpty) ...[
                const Text('OUTPUT LABELS', style: _headerStyle),
                const SizedBox(height: 8),
                ...List.generate(
                  outputNodes.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextField(
                      controller: outputControllers[i],
                      decoration: _inputDeco('Output ${i + 1} Label'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.isNotEmpty) {
              widget.controller.saveCurrentAsComponent(
                name: nameController.text,
                color: selectedColor,
                inputLabels: inputControllers.map((c) => c.text).toList(),
                outputLabels: outputControllers.map((c) => c.text).toList(),
                pinPlacements: pinPlacements,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Create IC'),
        ),
      ],
    );
  }
}
