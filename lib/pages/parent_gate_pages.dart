import 'dart:math';

import 'package:flutter/material.dart';

import '../main.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/progress_store.dart';
import 'admin_page.dart';
import 'auth_pages.dart';

/// The single gate every "go to parent stuff" entry point must pass
/// through: sign in with email/password if this device has never signed
/// in before, then — every single time, regardless of whether Firebase
/// still has a session open — solve a freshly-generated [RandomGatePage]
/// challenge before landing on [AdminPage]. There's no PIN to set up or
/// forget: the challenge is different every time, so a child who can't
/// yet read numbers spelled out as words can't get past it, but there's
/// nothing for a parent to remember either.
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

/// "Grown-Ups Only!" — three random digits, shown spelled out as words
/// ("FIVE, THREE, ZERO"), that the parent types back on a number pad. A
/// wrong attempt just rolls a brand new set rather than locking anyone
/// out, since the point isn't security against an adult, only against a
/// child who hasn't learned to read number words yet.
class RandomGatePage extends StatefulWidget {
  const RandomGatePage({super.key});

  @override
  State<RandomGatePage> createState() => _RandomGatePageState();
}

class _RandomGatePageState extends State<RandomGatePage> {
  static const _words = [
    'ZERO',
    'ONE',
    'TWO',
    'THREE',
    'FOUR',
    'FIVE',
    'SIX',
    'SEVEN',
    'EIGHT',
    'NINE',
  ];
  final _random = Random();
  late List<int> _digits;
  String _typed = '';
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    _roll();
  }

  void _roll() {
    _digits = List.generate(3, (_) => _random.nextInt(10));
    _typed = '';
    _wrong = false;
  }

  void _pressDigit(int digit) {
    if (_typed.length >= _digits.length) return;
    setState(() => _typed += '$digit');
    if (_typed.length != _digits.length) return;
    if (_typed == _digits.join()) {
      Navigator.pop(context, true);
    } else {
      setState(() => _wrong = true);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(_roll);
      });
    }
  }

  void _backspace() {
    if (_typed.isEmpty || _wrong) return;
    setState(() => _typed = _typed.substring(0, _typed.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final words = _digits.map((d) => _words[d]).join(', ');
    return Scaffold(
      appBar: AppBar(title: const Text('Grown-ups only')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
            final prompt = _GatePrompt(
              words: words,
              typed: _typed,
              length: _digits.length,
              wrong: _wrong,
            );
            final keyboard = _GateKeyboard(
              onDigit: _pressDigit,
              onBackspace: _backspace,
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
    required this.words,
    required this.typed,
    required this.length,
    required this.wrong,
  });

  final String words;
  final String typed;
  final int length;
  final bool wrong;

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
            'To continue, type these numbers:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          Text(
            words,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
              typed.padRight(length, '_').split('').join('  '),
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 8),
            ),
          ),
          if (wrong)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                "That's not it — here come new numbers.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _GateKeyboard extends StatelessWidget {
  const _GateKeyboard({required this.onDigit, required this.onBackspace});

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;

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
              _GateKey(label: '$n', onTap: () => onDigit(n)),
            const SizedBox.shrink(),
            _GateKey(label: '0', onTap: () => onDigit(0)),
            _GateKey(label: '⌫', onTap: onBackspace, isAction: true),
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
    this.isAction = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool isAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isAction ? Colors.black.withValues(alpha: 0.05) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
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
