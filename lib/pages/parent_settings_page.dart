import 'package:flutter/material.dart';

import '../services/accessibility_settings.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/narration_service.dart';
import '../services/parent_gate_service.dart';
import '../services/progress_store.dart';
import 'auth_pages.dart';

class ParentSettingsPage extends StatelessWidget {
  const ParentSettingsPage({
    required this.gateService,
    this.auth,
    this.store,
    this.firestore,
    super.key,
  });

  final ParentGateService gateService;
  final AuthService? auth;
  final ProgressStore? store;
  final FirestoreService? firestore;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            if (auth != null)
              _EmailBackupSection(
                auth: auth!,
                store: store,
                firestore: firestore,
              ),
            const _VoiceStatusRow(),
            const _ColorFriendlyModeRow(),
            _GrownUpLockSection(service: gateService),
          ],
        ),
      );
}

class _EmailBackupSection extends StatefulWidget {
  const _EmailBackupSection({required this.auth, this.store, this.firestore});

  final AuthService auth;
  final ProgressStore? store;
  final FirestoreService? firestore;

  @override
  State<_EmailBackupSection> createState() => _EmailBackupSectionState();
}

class _EmailBackupSectionState extends State<_EmailBackupSection> {
  Future<void> _openBackup() async {
    final linked = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => RegisterPage(
          auth: widget.auth,
          firestore: widget.firestore,
          store: widget.store,
        ),
      ),
    );
    if (linked == true && mounted) setState(() {});
  }

  Future<void> _openSignIn() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LoginPage(
          auth: widget.auth,
          firestore: widget.firestore,
          store: widget.store,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.currentUser;
    final emailLinked = widget.auth.hasEmailBackup && user?.email != null;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data backup',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(emailLinked
                ? 'Backed up as ${user!.email}'
                : 'Not backed up (this device only)'),
            const SizedBox(height: 6),
            if (!emailLinked) ...[
              const Text(
                'Without a backup, data is lost if you uninstall the app or change phone.',
              ),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: _openBackup,
                    child: const Text('Back up my data (link email)'),
                  ),
                  TextButton(
                    onPressed: _openSignIn,
                    child: const Text('I already have a backup (sign in)'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GrownUpLockSection extends StatefulWidget {
  const _GrownUpLockSection({required this.service});

  final ParentGateService service;

  @override
  State<_GrownUpLockSection> createState() => _GrownUpLockSectionState();
}

class _GrownUpLockSectionState extends State<_GrownUpLockSection> {
  late Future<ParentLockMethod?> _method;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _method = widget.service.selectedMethod;
  }

  Future<void> _showResult(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
                  const label = '4-digit PIN';
                  return Text('Current method: $label');
                },
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
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
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                voiceAvailable
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: voiceAvailable ? Colors.green : Colors.redAccent,
              ),
              const SizedBox(width: 8),
              Text(
                'Voice: ${voiceAvailable ? 'Ready' : 'Not available'}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
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
