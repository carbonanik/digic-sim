import 'dart:convert';

import 'package:flutter/material.dart';

import '../controllers/circuit_controller.dart';
import '../models/nodes/composed_node.dart';
import '../services/gemini_service.dart';

// ---------------------------------------------------------------------------
// Public entry-point: call this from the top-bar AI button
// ---------------------------------------------------------------------------

void showAiPromptDialog(BuildContext context, CircuitController controller) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (_) => _AiPromptDialog(controller: controller),
  );
}

// ---------------------------------------------------------------------------
// Internal state enum
// ---------------------------------------------------------------------------

enum _AiState { idle, loading, success, error }

// ---------------------------------------------------------------------------
// Dialog widget
// ---------------------------------------------------------------------------

class _AiPromptDialog extends StatefulWidget {
  final CircuitController controller;
  const _AiPromptDialog({required this.controller});

  @override
  State<_AiPromptDialog> createState() => _AiPromptDialogState();
}

class _AiPromptDialogState extends State<_AiPromptDialog>
    with SingleTickerProviderStateMixin {
  final _apiKeyController = TextEditingController();
  final _promptController = TextEditingController();

  _AiState _state = _AiState.idle;
  String _errorMessage = '';
  String _generatedJson = '';

  late final AnimationController _shimmerController;

  // Remembered across dialog sessions via static field (in-process only)
  static String _savedApiKey = '';

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = _savedApiKey;
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _promptController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final apiKey = _apiKeyController.text.trim();
    final prompt = _promptController.text.trim();

    if (apiKey.isEmpty) {
      setState(() {
        _state = _AiState.error;
        _errorMessage = 'Please enter your Gemini API key.';
      });
      return;
    }
    if (prompt.isEmpty) {
      setState(() {
        _state = _AiState.error;
        _errorMessage = 'Please describe the circuit you want to generate.';
      });
      return;
    }

    _savedApiKey = apiKey;

    setState(() {
      _state = _AiState.loading;
      _errorMessage = '';
      _generatedJson = '';
    });

    try {
      final json = await GeminiService.generateCircuit(
        apiKey: apiKey,
        prompt: prompt,
      );
      setState(() {
        _state = _AiState.success;
        _generatedJson = json;
      });
    } on GeminiException catch (e) {
      setState(() {
        _state = _AiState.error;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _state = _AiState.error;
        _errorMessage = e.toString();
      });
    }
  }

  void _applyToCanvas() {
    if (_generatedJson.isEmpty) return;
    try {
      final map = jsonDecode(_generatedJson) as Map<String, dynamic>;
      final definition = SubCircuitDefinition.fromMap(map);
      widget.controller.loadDefinition(definition);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Color(0xff4ade80), size: 18),
              const SizedBox(width: 12),
              const Text('Circuit generated and loaded on canvas!'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xff1e293b),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() {
        _state = _AiState.error;
        _errorMessage = 'Failed to parse circuit: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: const Color(0xff0b1120),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xff1f2937), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff38bdf8).withOpacity(0.08),
              blurRadius: 60,
              spreadRadius: 10,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 40,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const Divider(color: Color(0xff1f2937), height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildApiKeyField(),
                    const SizedBox(height: 20),
                    _buildPromptField(),
                    const SizedBox(height: 20),
                    _buildExamples(),
                    const SizedBox(height: 24),
                    _buildStateArea(),
                  ],
                ),
              ),
            ),
            const Divider(color: Color(0xff1f2937), height: 1),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
      child: Row(
        children: [
          // Animated AI icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff8b5cf6), Color(0xff06b6d4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff8b5cf6).withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Circuit Generator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Describe a circuit · Gemini builds it for you',
                  style: TextStyle(
                    color: const Color(0xff94a3b8).withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xff4b5563)),
            onPressed: () => Navigator.of(context).pop(),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('GEMINI API KEY', Icons.vpn_key_outlined),
        const SizedBox(height: 8),
        TextField(
          controller: _apiKeyController,
          obscureText: true,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
          decoration: _inputDeco(
            'AIza...',
            suffix: InkWell(
              onTap: () {
                // Toggle show/hide — handled by obscureText above
              },
              child: const Icon(Icons.key_rounded,
                  size: 18, color: Color(0xff4b5563)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 12, color: Color(0xff4b5563)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Get a free key at aistudio.google.com. Key is stored in memory only.',
                style: const TextStyle(
                  color: Color(0xff4b5563),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromptField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('CIRCUIT DESCRIPTION', Icons.text_fields_rounded),
        const SizedBox(height: 8),
        TextField(
          controller: _promptController,
          maxLines: 4,
          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          decoration: _inputDeco(
            'e.g. "Design a full adder circuit with inputs A, B, Cin and outputs Sum and Cout"',
          ),
          onSubmitted: (_) => _state != _AiState.loading ? _generate() : null,
        ),
      ],
    );
  }

  Widget _buildExamples() {
    final examples = [
      'Half Adder',
      '4-input OR gate',
      'SR Latch',
      'XOR from NAND',
      '2-to-1 Mux',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('QUICK EXAMPLES', Icons.bolt_rounded),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: examples.map((e) {
            return InkWell(
              onTap: () => _promptController.text = 'Design a $e circuit',
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xff1e293b),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xff334155)),
                ),
                child: Text(
                  e,
                  style: const TextStyle(
                    color: Color(0xff94a3b8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStateArea() {
    return switch (_state) {
      _AiState.idle => const SizedBox.shrink(),
      _AiState.loading => _buildLoadingCard(),
      _AiState.success => _buildSuccessCard(),
      _AiState.error => _buildErrorCard(),
    };
  }

  Widget _buildLoadingCard() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xff111827),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xff8b5cf6).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(
                      const Color(0xff8b5cf6),
                      const Color(0xff06b6d4),
                      _shimmerController.value,
                    )!,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generating circuit…',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gemini is designing your logic diagram',
                      style: TextStyle(
                        color: const Color(0xff94a3b8).withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff052e16).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xff4ade80).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xff4ade80), size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Circuit generated successfully!',
                  style: TextStyle(
                    color: Color(0xff4ade80),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xff020617),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xff1f2937)),
            ),
            child: Text(
              _generatedJson.length > 300
                  ? '${_generatedJson.substring(0, 300)}…'
                  : _generatedJson,
              style: const TextStyle(
                color: Color(0xff94a3b8),
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Press "Apply to Canvas" to load this circuit, or "Regenerate" to try again.',
            style: TextStyle(
              color: const Color(0xff94a3b8).withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff450a0a).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.redAccent.shade100, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generation failed',
                  style: TextStyle(
                    color: Colors.redAccent.shade100,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Color(0xfffca5a5),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final canApply = _state == _AiState.success;
    final isLoading = _state == _AiState.loading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Row(
        children: [
          // Regenerate / Generate button
          Expanded(
            child: _GradientButton(
              icon: isLoading
                  ? Icons.hourglass_top_rounded
                  : Icons.auto_awesome_rounded,
              label: isLoading
                  ? 'Generating…'
                  : (_state == _AiState.success ? 'Regenerate' : 'Generate'),
              onTap: isLoading ? null : _generate,
              gradient: const LinearGradient(
                colors: [Color(0xff7c3aed), Color(0xff0891b2)],
              ),
            ),
          ),
          if (canApply) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _GradientButton(
                icon: Icons.check_rounded,
                label: 'Apply to Canvas',
                onTap: _applyToCanvas,
                gradient: const LinearGradient(
                  colors: [Color(0xff059669), Color(0xff0891b2)],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _label(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xff4b5563)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xff64748b),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String hint, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xff374151), fontSize: 13),
        filled: true,
        fillColor: const Color(0xff0f172a),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff1f2937)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff1f2937)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff7c3aed), width: 2),
        ),
      );
}

// ---------------------------------------------------------------------------
// Gradient button
// ---------------------------------------------------------------------------

class _GradientButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Gradient gradient;

  const _GradientButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.gradient,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            gradient: enabled ? widget.gradient : null,
            color: enabled ? null : const Color(0xff1f2937),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered && enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: enabled ? Colors.white : const Color(0xff4b5563),
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  color: enabled ? Colors.white : const Color(0xff4b5563),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
