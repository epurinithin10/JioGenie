import 'package:flutter/material.dart';
import '../constants/jio_colors.dart';
import '../models/app_settings.dart';

class SettingsDialog extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSave;

  const SettingsDialog({
    super.key,
    required this.settings,
    required this.onSave,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late String _provider;
  late TextEditingController _apiKeyController;
  late TextEditingController _promptController;
  late double _temperature;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _provider = widget.settings.provider;
    _apiKeyController = TextEditingController(text: widget.settings.apiKey);
    _promptController = TextEditingController(text: widget.settings.systemPrompt);
    _temperature = widget.settings.temperature;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _save() {
    final updated = AppSettings(
      provider: _provider,
      apiKey: _apiKeyController.text.trim(),
      systemPrompt: _promptController.text.trim(),
      temperature: _temperature,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.tune_rounded, color: JioColors.jioNavy, size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'JioGenie Engine Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: JioColors.jioNavy,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: JioColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Active Engine
              const Text(
                'Active Engine',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: JioColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: JioColors.borderDefault),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _provider,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'groq',
                        child: Text('⚡ Groq Cloud LPU + Jio.com RAG (Connected)'),
                      ),
                      DropdownMenuItem(
                        value: 'mock',
                        child: Text('Offline Smart Simulation'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _provider = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Groq API Key
              const Text(
                'Groq API Key',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: JioColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _apiKeyController,
                obscureText: _obscureKey,
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Enter your Groq API key',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: JioColors.borderDefault),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureKey ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 18,
                      color: JioColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // System Persona & Prompt
              const Text(
                'System Persona & Prompt',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: JioColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _promptController,
                minLines: 3,
                maxLines: 4,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: JioColors.borderDefault),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),

              // Temperature
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Temperature (Creativity)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: JioColors.textPrimary),
                  ),
                  Text(
                    _temperature.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: JioColors.jioBlue,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: JioColors.jioBlue,
                  thumbColor: JioColors.jioBlue,
                  overlayColor: JioColors.jioBlue.withValues(alpha: 0.15),
                ),
                child: Slider(
                  value: _temperature,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (val) => setState(() => _temperature = val),
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: JioColors.textSecondary)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: JioColors.jioBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
