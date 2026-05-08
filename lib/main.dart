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
          const Spacer(),
          FilledButton.icon(
            onPressed: controller.clear,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
