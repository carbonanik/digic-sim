import 'package:digital_logic_sim_2/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:digital_logic_sim_2/features/component_library/preset_library.dart';
import 'package:digital_logic_sim_2/presentation/controllers/circuit_controller.dart';
import 'package:digital_logic_sim_2/presentation/screens/logic_designer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PresetLibrary.initialize();
  await CircuitController.initializeCustomDefinitions();
  runApp(const LogicDesignerApp());
}

class LogicDesignerApp extends StatelessWidget {
  const LogicDesignerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
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
