import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/parent_gate_service.dart';
import '../services/progress_store.dart';
import '../theme/adaptive_metrics.dart';
import '../theme/tinymind_colors.dart';
import '../widgets/emoji_glyph.dart';
import 'admin_page.dart';
import 'auth_pages.dart';
import 'edit_child_page.dart';

/// The single gate every "go to parent stuff" entry point must pass through.
Future<void> openParentArea(
  BuildContext context, {
  AuthService? auth,
  ParentGateService? gateService,
  ProgressStore? store,
  FirestoreService? firestore,
  bool skipGate = false,
}) async {
  try {
    final authService = auth ?? AuthService();
    final user = authService.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please try again in a moment.')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    final gate = gateService ?? ParentGateService.instance;
    final unlocked = skipGate || await gate.unlock(context);
    if (!unlocked || !context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AdminPage(
          auth: authService,
          gateService: gate,
          store: store,
          firestore: firestore,
        ),
      ),
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
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
    ParentGateService? gateService,
    super.key,
  })  : firestore = firestore ?? FirestoreService(),
        auth = auth ?? AuthService(),
        gateService = gateService ?? ParentGateService.instance;

  final ProgressStore store;
  final String parentUid;
  final FirestoreService firestore;
  final AuthService auth;
  final ParentGateService gateService;

  @override
  State<ChildPickerPage> createState() => _ChildPickerPageState();
}

class _ChildPickerPageState extends State<ChildPickerPage> {
  bool _managing = false;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _children =
      widget.firestore.watchChildren(widget.parentUid);
  int _attempt = 0;
  Timer? _autoRetryTimer;
  bool _autoRetried = false;

  /// Refreshes the sign-in token first, since an expired token is a common
  /// reason for the error. If the account has changed in the meantime, this
  /// page's uid is stale, so start again instead of retrying it.
  Future<void> _retry() async {
    _autoRetryTimer?.cancel();
    _autoRetryTimer = null;
    try {
      await widget.auth.currentUser?.getIdToken(true);
    } catch (_) {}
    if (!mounted) return;
    final uid = widget.auth.currentUser?.uid;
    if (uid == null || uid != widget.parentUid) {
      await restartToStartup(
        context,
        store: widget.store,
        auth: widget.auth,
        firestore: widget.firestore,
      );
      return;
    }
    setState(() {
      _children = widget.firestore.watchChildren(widget.parentUid);
      _attempt++;
    });
  }

  /// Retries once on its own, 2 seconds after an error.
  void _scheduleAutoRetry() {
    if (_autoRetried || _autoRetryTimer != null) return;
    _autoRetried = true;
    _autoRetryTimer = Timer(const Duration(seconds: 2), () {
      _autoRetryTimer = null;
      if (mounted) _retry();
    });
  }

  @override
  void dispose() {
    _autoRetryTimer?.cancel();
    super.dispose();
  }

  /// A short code for the error, so a parent can report it without the
  /// raw message being shown.
  String _errorCode(Object? error) =>
      error is FirebaseException ? error.code : '${error.runtimeType}';

  /// The raw error message, cut to 80 characters.
  String _errorMessage(Object? error) {
    final message = error is FirebaseException
        ? (error.message ?? '')
        : '${error ?? ''}';
    return message.length > 80 ? message.substring(0, 80) : message;
  }

  /// Small lines about the signed-in account, to help diagnose the error.
  List<String> _accountDiagnostics() {
    final user = widget.auth.currentUser;
    if (user == null) return const ['signed out'];
    final uid = user.uid;
    final uidTail = uid.length > 6 ? uid.substring(uid.length - 6) : uid;
    final providers =
        user.providerData.map((info) => info.providerId).join(', ');
    return [
      'uid …$uidTail',
      'anonymous: ${user.isAnonymous ? 'yes' : 'no'}',
      'providers: ${providers.isEmpty ? 'none' : providers}',
    ];
  }

  /// Signs out and starts fresh after the parent confirms. Offered when the
  /// account itself is the problem, so retrying cannot help.
  Future<void> _startOver() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start over?'),
        content: const SingleChildScrollView(
          child: Text(
            'This phone will sign out of this account and start fresh. '
            'Children saved only on this phone may be lost if you have not '
            'backed up.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Start over'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _autoRetryTimer?.cancel();
    _autoRetryTimer = null;
    try {
      await widget.auth.signOut();
    } catch (_) {}
    if (!mounted) return;
    await restartToStartup(
      context,
      store: widget.store,
      auth: widget.auth,
      firestore: widget.firestore,
    );
  }

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
        builder: (_) => ChildProfilePage(
          store: widget.store,
          auth: widget.auth,
          firestore: widget.firestore,
        ),
      ),
    );
  }

  Future<void> _startManaging() async {
    final unlocked = await widget.gateService.unlock(context);
    if (unlocked == true && mounted) setState(() => _managing = true);
  }

  Future<void> _editChild(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data();
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => EditChildPage(
          store: widget.store,
          firestore: widget.firestore,
          parentUid: widget.parentUid,
          childId: doc.id,
          name: (data['name'] as String?) ?? 'Little Learner',
          avatar: (data['avatar'] as String?) ?? '🧒',
          age: (data['age'] as num?)?.toInt() ?? 4,
        ),
      ),
    );
  }

  Future<void> _removeChild(String childId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Remove $name?'),
        ),
        content: const SingleChildScrollView(
          child: Text('This deletes their progress.'),
        ),
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
        key: ValueKey(_attempt),
        stream: _children,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            _scheduleAutoRetry();
            final code = _errorCode(snapshot.error);
            final message = _errorMessage(snapshot.error);
            final canStartOver =
                code == 'permission-denied' || code == 'unauthenticated';
            const smallStyle = TextStyle(fontSize: 12, color: Colors.black45);
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'We could not load the pictures.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '($code)',
                      textAlign: TextAlign.center,
                      style: smallStyle,
                    ),
                    if (message.isNotEmpty)
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: smallStyle,
                      ),
                    for (final line in _accountDiagnostics())
                      Text(line, textAlign: TextAlign.center, style: smallStyle),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton(
                          onPressed: _retry,
                          child: const Text('Retry'),
                        ),
                        if (canStartOver)
                          TextButton(
                            onPressed: _startOver,
                            child: const Text('Start over'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          _autoRetried = false;
          final children = snapshot.data!.docs;
          return SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final total = children.length + 1;
                      final availableWidth = constraints.maxWidth - 24;
                      final columns =
                          (availableWidth / 108).floor().clamp(1, total);
                      final rows = (total / columns).ceil();
                      final spacing = 8.0;
                      final metrics =
                          AdaptiveMetrics.fromConstraints(context, constraints);
                      final compact = constraints.maxHeight < 400 &&
                          constraints.maxWidth > constraints.maxHeight;
                      final logoSize = compact ? 56.0 : 72.0;
                      final itemWidth =
                          (availableWidth - spacing * (columns - 1)) / columns;
                      final itemHeight = ((constraints.maxHeight - 100) / rows)
                          .clamp(104.0, 150.0)
                          .toDouble();
                      // Leaves room for the name when many children make the
                      // rows short.
                      final avatarRadius = min(
                        (itemWidth * 0.31)
                                .clamp(metrics.size(20), metrics.size(42))
                                .toDouble() *
                            1.15,
                        (itemHeight - 30) / 2,
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(minHeight: constraints.maxHeight),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.asset(
                                        'assets/branding/tinymind_launcher.png',
                                        width: logoSize,
                                        height: logoSize,
                                        semanticLabel: 'TinyMind',
                                      ),
                                    ),
                                    Text(
                                      'TinyMind',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontSize: compact ? 32 : 40,
                                            fontWeight: FontWeight.w900,
                                            color: TinyMindColors.textDark,
                                          ),
                                    ),
                                  ],
                                ),
                                Center(
                                  child: Wrap(
                                    spacing: spacing,
                                    runSpacing: 4,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      for (final doc in children)
                                        _FlatChildAvatar(
                                          name: (doc.data()['name'] as String?) ??
                                              'Little Learner',
                                          avatar: (doc.data()['avatar'] as String?) ??
                                              '🧒',
                                          width: itemWidth,
                                          height: itemHeight,
                                          avatarRadius: avatarRadius,
                                          managing: _managing,
                                          onDelete: () => _removeChild(
                                            doc.id,
                                            (doc.data()['name'] as String?) ??
                                                'Little Learner',
                                          ),
                                          onTap: _managing
                                              ? () => _editChild(doc)
                                              : () => _selectChild(doc.id),
                                        ),
                                      _FlatAddAvatar(
                                        width: itemWidth,
                                        height: itemHeight,
                                        avatarRadius: avatarRadius,
                                        onTap: _managing ? () {} : _addChild,
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => openParentArea(
                                    context,
                                    auth: widget.auth,
                                    store: widget.store,
                                    firestore: widget.firestore,
                                  ),
                                  icon: const Icon(Icons.family_restroom_rounded,
                                      size: 18, color: Colors.black45),
                                  label: const Text('For parents',
                                      style: TextStyle(color: Colors.black45)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    onPressed: _managing
                        ? () => setState(() => _managing = false)
                        : _startManaging,
                    tooltip: _managing ? 'Done' : 'Manage',
                    iconSize: 24,
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    color: Colors.black54,
                    icon: Icon(
                      _managing ? Icons.check_rounded : Icons.edit_outlined,
                    ),
                  ),
                ),
              ],
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
    required this.onDelete,
  });
  final String name;
  final String avatar;
  final VoidCallback onTap;
  final VoidCallback onDelete;
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
                  child: EmojiGlyph(avatar, avatarRadius * 0.9),
                ),
                if (managing) ...[
                  const Positioned(
                    left: -3,
                    bottom: -3,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFF3D8BFD),
                      child: Icon(Icons.edit_rounded,
                          size: 14, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Tooltip(
                      message: 'Remove $name',
                      child: InkWell(
                        key: Key('remove-child-$name'),
                        onTap: onDelete,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  name,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
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
