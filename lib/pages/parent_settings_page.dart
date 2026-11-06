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
  Widget build(BuildContext context) {
    final cards = <Widget>[
      if (auth != null)
        _EmailBackupSection(
          auth: auth!,
          store: store,
          firestore: firestore,
        ),
      _ParentLockSection(service: gateService),
      const _VoiceStatusRow(),
      const _ColorFriendlyModeRow(),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 12.0;
          final rows = <Widget>[];
          if (constraints.maxWidth >= 560) {
            for (var i = 0; i < cards.length; i += 2) {
              rows.add(
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: cards[i]),
                      const SizedBox(width: spacing),
                      Expanded(
                        child: i + 1 < cards.length
                            ? cards[i + 1]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            }
          } else {
            rows.addAll(cards);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: spacing),
                rows[i],
              ],
            ],
          );
        },
      ),
    );
  }
}

const _cardTitleStyle = TextStyle(fontSize: 17, fontWeight: FontWeight.w800);

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
    final backedUp = widget.auth.hasBackup;
    final email = user?.email;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Data backup', style: _cardTitleStyle),
            const SizedBox(height: 6),
            Text(!backedUp
                ? 'Not backed up (this device only)'
                : email != null && email.isNotEmpty
                    ? 'Backed up as $email'
                    : 'Backed up'),
            const SizedBox(height: 6),
            if (!backedUp) ...[
              const Text(
                'Without a backup, data is lost if you uninstall the app or change phone.',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _openBackup,
                  child: const Text('Back up my data'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _openSignIn,
                  child: const Text(
                    'I already have a backup (sign in)',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ParentLockSection extends StatefulWidget {
  const _ParentLockSection({required this.service});

  final ParentGateService service;

  @override
  State<_ParentLockSection> createState() => _ParentLockSectionState();
}

class _ParentLockSectionState extends State<_ParentLockSection> {
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
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Parent lock', style: _cardTitleStyle),
              const SizedBox(height: 6),
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
              const SizedBox(height: 10),
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
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Voice', style: _cardTitleStyle),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  voiceAvailable
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  color: voiceAvailable ? Colors.green : Colors.redAccent,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Voice: ${voiceAvailable ? 'Ready' : 'Not available'}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
    final onChanged =
        _saving ? null : (bool enabled) => _save(settings, enabled);
    // A plain Row/Column instead of SwitchListTile: ListTile under-reports
    // its intrinsic height when the subtitle wraps, so the IntrinsicHeight
    // row in the settings grid made this card too short.
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onChanged == null
                    ? null
                    : () => onChanged(!settings.colorFriendlyMode),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Color-friendly mode', style: _cardTitleStyle),
                    SizedBox(height: 4),
                    Text(
                      'Adds patterns and names to colors for children '
                      'who have trouble telling colors apart.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: settings.colorFriendlyMode,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
