import 'package:digital_logic_sim_2/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_logic_sim_2/presentation/providers/editor_dependencies.dart';
import 'package:digital_logic_sim_2/features/component_library/preset_library.dart';
import 'package:digital_logic_sim_2/core/di/injection.dart';
import 'package:digital_logic_sim_2/presentation/screens/logic_designer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PresetLibrary.initialize();
  final dependencies = AppDependencies.production();
  await dependencies.initialize();
  runApp(LogicDesignerApp(dependencies: dependencies));
}

class LogicDesignerApp extends StatelessWidget {
  final AppDependencies dependencies;

  const LogicDesignerApp({super.key, required this.dependencies});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        circuitSimulatorProvider.overrideWithValue(dependencies.simulator),
        customComponentManagerProvider.overrideWithValue(
          dependencies.customComponents,
        ),
        generateCircuitProvider.overrideWithValue(dependencies.generateCircuit),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}
