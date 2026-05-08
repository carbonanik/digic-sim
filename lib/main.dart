import 'package:flutter/material.dart';

import 'controllers/circuit_controller.dart';
import 'editor/circuit_canvas.dart';
import 'widgets/component_toolbar.dart';

void main() {
  runApp(const LogicDesignerApp());
}

class LogicDesignerApp extends StatelessWidget {
  const LogicDesignerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logic Designer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff0f172a),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff38bdf8),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LogicDesignerScreen(),
    );
  }
}

class LogicDesignerScreen extends StatefulWidget {
  const LogicDesignerScreen({super.key});

  @override
  State<LogicDesignerScreen> createState() => _LogicDesignerScreenState();
}

class _LogicDesignerScreenState extends State<LogicDesignerScreen> {
  final CircuitController controller = CircuitController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Row(
            children: [
              ComponentToolbar(controller: controller),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(controller: controller),
                    Expanded(child: CircuitCanvas(controller: controller)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final CircuitController controller;

  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xff111827),
        border: Border(bottom: BorderSide(color: Color(0xff1f2937))),
      ),
      child: Row(
        children: [
          const Text(
            'Digital Logic Designer',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xff1e293b),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Tool: ${controller.selectedTool.name.toUpperCase()}',
              style: const TextStyle(fontSize: 12, color: Color(0xff93c5fd)),
            ),
          ),
          FilledButton.icon(
            onPressed: controller.undo,
            icon: const Icon(Icons.undo),
            label: const Text('Undo'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: controller.redo,
            icon: const Icon(Icons.redo),
            label: const Text('Redo'),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => _showSaveDialog(context),
            icon: const Icon(Icons.save_alt),
            label: const Text('Save as IC'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff1e3a8a),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: controller.clear,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    final inputNodes = controller.circuit.nodes.whereType<InputNode>().toList();
    final outputNodes = controller.circuit.nodes.whereType<OutputNode>().toList();
    
    final nameController = TextEditingController();
    final inputControllers = List.generate(inputNodes.length, (_) => TextEditingController());
    final outputControllers = List.generate(outputNodes.length, (_) => TextEditingController());
    
    Color selectedColor = const Color(0xff1e3a8a);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                    ].map((color) => GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                  if (inputNodes.isNotEmpty) ...[
                    const Text('INPUT LABELS', style: _headerStyle),
                    const SizedBox(height: 8),
                    ...List.generate(inputNodes.length, (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TextField(
                        controller: inputControllers[i],
                        decoration: _inputDeco('Input ${i+1} Label'),
                      ),
                    )),
                    const SizedBox(height: 12),
                  ],
                  if (outputNodes.isNotEmpty) ...[
                    const Text('OUTPUT LABELS', style: _headerStyle),
                    const SizedBox(height: 8),
                    ...List.generate(outputNodes.length, (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TextField(
                        controller: outputControllers[i],
                        decoration: _inputDeco('Output ${i+1} Label'),
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  controller.saveCurrentAsComponent(
                    name: nameController.text,
                    color: selectedColor,
                    inputLabels: inputControllers.map((c) => c.text).toList(),
                    outputLabels: outputControllers.map((c) => c.text).toList(),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create IC'),
            ),
          ],
        ),
      ),
    );
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
}
