import 'package:flutter/material.dart';

import '../services/accessibility_settings.dart';
import '../services/narration_service.dart';
import '../services/parent_gate_service.dart';

class ParentSettingsPage extends StatelessWidget {
  const ParentSettingsPage({
    required this.gateService,
    super.key,
  });

  final ParentGateService gateService;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const _VoiceStatusRow(),
            const _ColorFriendlyModeRow(),
            _GrownUpLockSection(service: gateService),
          ],
        ),
      );
}

class _GrownUpLockSection extends StatefulWidget {
  const _GrownUpLockSection({required this.service});

  final ParentGateService service;

  @override
  State<_GrownUpLockSection> createState() => _GrownUpLockSectionState();
}

class _GrownUpLockSectionState extends State<_GrownUpLockSection> {
  late Future<ParentLockMethod?> _method;
  late Future<bool> _phoneSupported;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _method = widget.service.selectedMethod;
    _phoneSupported = widget.service.canUsePhoneUnlock;
  }

  Future<void> _showResult(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _usePhone() async {
    try {
      final changed = await widget.service.usePhoneUnlock();
      if (!mounted) return;
      if (changed) {
        setState(_refresh);
      } else {
        await _showResult('Set up a phone screen lock before choosing this.');
      }
    } catch (error) {
      await _showResult('Could not change the grown-up lock: $error');
    }
  }

  Future<void> _usePin() async {
    try {
      final changed = await widget.service.usePin(context);
      if (!mounted || !changed) return;
      setState(_refresh);
    } catch (error) {
      await _showResult('Could not save the PIN: $error');
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Grown-up lock',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              FutureBuilder<ParentLockMethod?>(
                future: _method,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Current method: Could not load');
                  }
                  if (!snapshot.hasData) {
                    return const Text('Current method: Loading...');
                  }
                  final label = switch (snapshot.data) {
                    ParentLockMethod.phone => 'Phone unlock',
                    ParentLockMethod.pin => '4-digit PIN',
                    _ => 'Not set up',
                  };
                  return Text('Current method: $label');
                },
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FutureBuilder<bool>(
                    future: _phoneSupported,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(
                          'Phone unlock is unavailable: ${snapshot.error}',
                        );
                      }
                      return OutlinedButton.icon(
                        onPressed: snapshot.data == true ? _usePhone : null,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: const Text('Use phone unlock'),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    onPressed: _usePin,
                    icon: const Icon(Icons.dialpad_rounded),
                    label: const Text('Use a 4-digit PIN'),
                  ),
                  TextButton(
                    onPressed: _usePin,
                    child: const Text('Change PIN'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _VoiceStatusRow extends StatelessWidget {
  const _VoiceStatusRow();

  @override
  Widget build(BuildContext context) {
    final voiceAvailable = NarrationService.instance.voiceAvailable;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Icon(
            voiceAvailable ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            color: voiceAvailable ? Colors.green : Colors.redAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Voice: ${voiceAvailable ? 'Ready' : 'Not available'}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          OutlinedButton.icon(
            onPressed: voiceAvailable
                ? () => NarrationService.instance
                    .speak('This is TinyMind. Can you hear me?')
                : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Play test voice'),
          ),
        ],
      ),
    );
  }
}

class _ColorFriendlyModeRow extends StatefulWidget {
  const _ColorFriendlyModeRow();

  @override
  State<_ColorFriendlyModeRow> createState() => _ColorFriendlyModeRowState();
}

class _ColorFriendlyModeRowState extends State<_ColorFriendlyModeRow> {
  bool _saving = false;

  Future<void> _save(AccessibilitySettings settings, bool enabled) async {
    setState(() => _saving = true);
    try {
      await settings.setColorFriendlyMode(enabled);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save setting: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AccessibilitySettingsScope.of(context);
    return SwitchListTile(
      title: const Text('Color-friendly mode'),
      subtitle: const Text(
        'Adds patterns and names to colors for children '
        'who have trouble telling colors apart.',
      ),
      value: settings.colorFriendlyMode,
      onChanged: _saving ? null : (enabled) => _save(settings, enabled),
    );
  }
}
