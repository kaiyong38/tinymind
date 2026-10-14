import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/parent_gate_service.dart';
import '../services/progress_store.dart';
import '../theme/adaptive_metrics.dart';
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
        stream: widget.firestore.watchChildren(widget.parentUid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('We could not load the pictures.'));
          }
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
                final metrics =
                    AdaptiveMetrics.fromConstraints(context, constraints);
                final itemWidth =
                    (availableWidth - spacing * (columns - 1)) / columns;
                final itemHeight = ((constraints.maxHeight - 100) / rows)
                    .clamp(104.0, 150.0)
                    .toDouble();
                final avatarRadius = (itemWidth * 0.31)
                        .clamp(metrics.size(20), metrics.size(42))
                        .toDouble() *
                    1.15;
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
                              const EmojiGlyph('🌈', 36),
                              const Text(
                                'Who is playing?',
                                style: TextStyle(
                                    fontSize: 27, fontWeight: FontWeight.w900),
                              ),
                              TextButton(
                                onPressed: _managing
                                    ? () => setState(() => _managing = false)
                                    : _startManaging,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                  textStyle: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: Text(_managing ? 'Done' : 'Manage'),
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
