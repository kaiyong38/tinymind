import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/parent_gate_question.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/progress_store.dart';
import 'admin_page.dart';
import 'auth_pages.dart';

/// The single gate every "go to parent stuff" entry point must pass
/// through: sign in with email/password if this device has never signed
/// in before, then — every single time, regardless of whether Firebase
/// still has a session open — solve a freshly-generated [RandomGatePage]
/// arithmetic challenge before landing on [AdminPage]. The challenge
/// changes every time, so there is nothing for a parent to remember.
Future<void> openParentArea(BuildContext context, {AuthService? auth}) async {
  try {
    final authService = auth ?? AuthService();
    if (authService.currentUser == null) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => LoginPage(auth: authService)),
      );
      if (!context.mounted || authService.currentUser == null) return;
    }
    final uid = authService.currentUser!.uid;
    if (!context.mounted) return;
    final unlocked = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => const RandomGatePage()),
    );
    if (unlocked != true || !context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => AdminPage(parentUid: uid)),
    );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open parent tools: $error')),
      );
    }
  }
}

/// "Grown-Ups Only!" — an arithmetic question that a parent answers on the
/// number pad. Three consecutive wrong answers start a short lockout.
class RandomGatePage extends StatefulWidget {
  const RandomGatePage({super.key});

  @override
  State<RandomGatePage> createState() => _RandomGatePageState();
}

class _RandomGatePageState extends State<RandomGatePage> {
  static const _lockoutDuration = Duration(seconds: 30);
  late ParentGateQuestion _question;
  String _typed = '';
  bool _wrong = false;
  int _failedAttempts = 0;
  int _lockoutSecondsRemaining = 0;
  DateTime? _lockedUntil;
  Timer? _lockoutTimer;

  bool get _isLocked => _lockedUntil?.isAfter(DateTime.now()) ?? false;

  @override
  void initState() {
    super.initState();
    _roll();
  }

  void _roll() {
    _question = generateParentGateQuestion();
    _typed = '';
    _wrong = false;
  }

  void _pressDigit(int digit) {
    if (_typed.length >= 3 || _wrong || _isLocked) return;
    setState(() => _typed += '$digit');
    if (int.parse(_typed) == _question.answer) {
      Navigator.pop(context, true);
      return;
    }
    if (_typed.length != 3) return;

    setState(() {
      _wrong = true;
      _failedAttempts++;
      if (_failedAttempts >= 3) {
        _lockedUntil = DateTime.now().add(_lockoutDuration);
        _lockoutSecondsRemaining = _lockoutDuration.inSeconds;
      }
    });
    if (_lockedUntil != null) _startLockoutTimer();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(_roll);
    });
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = _lockedUntil!.difference(DateTime.now()).inMilliseconds;
      setState(() {
        if (remaining <= 0) {
          timer.cancel();
          _lockedUntil = null;
          _failedAttempts = 0;
          _lockoutSecondsRemaining = 0;
        } else {
          _lockoutSecondsRemaining =
              (remaining + 999) ~/ Duration.millisecondsPerSecond;
        }
      });
    });
  }

  void _backspace() {
    if (_typed.isEmpty || _wrong || _isLocked) return;
    setState(() => _typed = _typed.substring(0, _typed.length - 1));
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grown-ups only')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
            final prompt = _GatePrompt(
              question: _question.expression,
              typed: _typed,
              wrong: _wrong,
              locked: _isLocked,
              lockoutSecondsRemaining: _lockoutSecondsRemaining,
            );
            final keyboard = _GateKeyboard(
              onDigit: _pressDigit,
              onBackspace: _backspace,
              enabled: !_wrong && !_isLocked,
            );
            return Padding(
              padding: const EdgeInsets.all(12),
              child: landscape
                  ? Row(
                      children: [
                        Expanded(child: Center(child: prompt)),
                        const SizedBox(width: 16),
                        Expanded(child: keyboard),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(flex: 5, child: Center(child: prompt)),
                        const SizedBox(height: 8),
                        Expanded(flex: 6, child: keyboard),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _GatePrompt extends StatelessWidget {
  const _GatePrompt({
    required this.question,
    required this.typed,
    required this.wrong,
    required this.locked,
    required this.lockoutSecondsRemaining,
  });

  final String question;
  final String typed;
  final bool wrong;
  final bool locked;
  final int lockoutSecondsRemaining;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shield_rounded, size: 42, color: Color(0xFFFF6FA5)),
          const SizedBox(height: 4),
          const Text(
            'Grown-Ups Only!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Solve this to continue:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          Text(
            question,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: wrong
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: wrong ? Colors.red : Colors.black12,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              typed.padRight(3, '_').split('').join('  '),
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 8),
            ),
          ),
          if (wrong)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                "That's not right. Here's a new question.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          if (locked)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Please wait $lockoutSecondsRemaining seconds, then try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            )
        ],
      ),
    );
  }
}

class _GateKeyboard extends StatelessWidget {
  const _GateKeyboard({
    required this.onDigit,
    required this.onBackspace,
    required this.enabled,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - 16) / 3;
        final cellHeight = (constraints.maxHeight - 24) / 4;
        final aspectRatio = cellWidth / cellHeight;
        return GridView.count(
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: aspectRatio,
          children: [
            for (var n = 1; n <= 9; n++)
              _GateKey(label: '$n', onTap: () => onDigit(n), enabled: enabled),
            const SizedBox.shrink(),
            _GateKey(label: '0', onTap: () => onDigit(0), enabled: enabled),
            _GateKey(
              label: '⌫',
              onTap: onBackspace,
              isAction: true,
              enabled: enabled,
            ),
          ],
        );
      },
    );
  }
}

class _GateKey extends StatelessWidget {
  const _GateKey({
    required this.label,
    required this.onTap,
    required this.enabled,
    this.isAction = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool isAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isAction || !enabled
          ? Colors.black.withValues(alpha: 0.05)
          : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

/// Lets a family pick which child is playing right now, from every learner
/// the signed-in parent has added — this is what fixed the bug where a
/// second child ("Kai") silently overwrote the first ("Mei"): every child
/// now gets their own id instead of the app assuming there is only one.
class ChildPickerPage extends StatefulWidget {
  ChildPickerPage({
    required this.store,
    required this.parentUid,
    FirestoreService? firestore,
    AuthService? auth,
    super.key,
  })  : firestore = firestore ?? FirestoreService(),
        auth = auth ?? AuthService();

  final ProgressStore store;
  final String parentUid;
  final FirestoreService firestore;
  final AuthService auth;

  @override
  State<ChildPickerPage> createState() => _ChildPickerPageState();
}

class _ChildPickerPageState extends State<ChildPickerPage> {
  bool _managing = false;

  Future<void> _selectChild(String childId) async {
    widget.store.configureChild(parentUid: widget.parentUid, childId: childId);
    await widget.store.load();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => TinyMindHomeShell(store: widget.store),
      ),
      (route) => false,
    );
  }

  Future<void> _addChild() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            ChildProfilePage(store: widget.store, auth: widget.auth),
      ),
    );
  }

  Future<void> _startManaging() async {
    final unlocked = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => const RandomGatePage()),
    );
    if (unlocked == true && mounted) setState(() => _managing = true);
  }

  Future<void> _removeChild(String childId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove $name?'),
        content: const Text('This deletes their progress.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.firestore.deleteChild(widget.parentUid, childId);
      await widget.store.clearCachedChildIfMatches(childId);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove $name: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder(
        stream: widget.firestore.watchChildren(widget.parentUid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final children = snapshot.data!.docs;
          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final total = children.length + 1;
                final availableWidth = constraints.maxWidth - 24;
                final columns = (availableWidth / 108).floor().clamp(1, total);
                final rows = (total / columns).ceil();
                final spacing = 8.0;
                final itemWidth =
                    (availableWidth - spacing * (columns - 1)) / columns;
                final itemHeight = (constraints.maxHeight - 100) / rows;
                final avatarRadius =
                    (itemWidth * 0.31).clamp(20.0, 42.0).toDouble();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 44,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🌈', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 8),
                            const Text(
                              'Who is playing?',
                              style: TextStyle(
                                  fontSize: 21, fontWeight: FontWeight.w900),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _managing
                                  ? () => setState(() => _managing = false)
                                  : _startManaging,
                              child: Text(_managing ? 'Done' : 'Manage'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Wrap(
                            spacing: spacing,
                            runSpacing: 4,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final doc in children)
                                _FlatChildAvatar(
                                  name: (doc.data()['name'] as String?) ??
                                      'Little Learner',
                                  avatar:
                                      (doc.data()['avatar'] as String?) ?? '🧒',
                                  width: itemWidth,
                                  height: itemHeight.clamp(0.0, 150.0),
                                  avatarRadius: avatarRadius,
                                  managing: _managing,
                                  onTap: _managing
                                      ? () => _removeChild(
                                            doc.id,
                                            (doc.data()['name'] as String?) ??
                                                'Little Learner',
                                          )
                                      : () => _selectChild(doc.id),
                                ),
                              _FlatAddAvatar(
                                width: itemWidth,
                                height: itemHeight.clamp(0.0, 150.0),
                                avatarRadius: avatarRadius,
                                onTap: _managing ? () {} : _addChild,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        child: TextButton.icon(
                          onPressed: () =>
                              openParentArea(context, auth: widget.auth),
                          icon: const Icon(Icons.family_restroom_rounded,
                              size: 18, color: Colors.black45),
                          label: const Text('For parents',
                              style: TextStyle(color: Colors.black45)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// A plain circular avatar with a name underneath — closer to the quiet,
/// "one big friendly icon" style of a kids'-app profile picker than a
/// bordered card.
class _FlatChildAvatar extends StatelessWidget {
  const _FlatChildAvatar({
    required this.name,
    required this.avatar,
    required this.onTap,
    required this.width,
    required this.height,
    required this.avatarRadius,
    required this.managing,
  });
  final String name;
  final String avatar;
  final VoidCallback onTap;
  final double width;
  final double height;
  final double avatarRadius;
  final bool managing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: const Color(0xFFFFD166),
                  child: Text(avatar,
                      style: TextStyle(fontSize: avatarRadius * 0.9)),
                ),
                if (managing)
                  const Positioned(
                    right: -3,
                    top: -3,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlatAddAvatar extends StatelessWidget {
  const _FlatAddAvatar({
    required this.onTap,
    required this.width,
    required this.height,
    required this.avatarRadius,
  });
  final VoidCallback onTap;
  final double width;
  final double height;
  final double avatarRadius;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.black.withValues(alpha: 0.06),
              child: Icon(Icons.add_rounded,
                  size: avatarRadius * 0.9, color: Colors.black45),
            ),
            const SizedBox(height: 4),
            const Text(
              'New',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
