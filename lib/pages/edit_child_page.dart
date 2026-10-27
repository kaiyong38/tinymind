import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/firestore_service.dart';
import '../services/progress_store.dart';
import '../widgets/emoji_glyph.dart';
import 'auth_pages.dart';

const editSavedOfflineMessage =
    'Saved on this phone. It will sync when you are online.';

/// Lets a parent change a child's nickname, age and avatar. It is only
/// reachable from the child picker's Manage mode, which already asked for the
/// parent PIN, so it does not ask again.
class EditChildPage extends StatefulWidget {
  const EditChildPage({
    required this.store,
    required this.firestore,
    required this.parentUid,
    required this.childId,
    required this.name,
    required this.avatar,
    required this.age,
    this.saveTimeout = const Duration(seconds: 3),
    super.key,
  });

  final ProgressStore store;
  final FirestoreService firestore;
  final String parentUid;
  final String childId;
  final String name;
  final String avatar;
  final int age;
  final Duration saveTimeout;

  @override
  State<EditChildPage> createState() => _EditChildPageState();
}

class _EditChildPageState extends State<EditChildPage> {
  late final TextEditingController _name;
  late String _avatar;
  late int _age;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.name);
    _avatar = widget.avatar;
    _age = childAgeChoices.contains(widget.age) ? widget.age : 4;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text;
    if (!isValidNickname(name)) {
      setState(() => _error = nicknameErrorText);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    var savedOnline = true;
    try {
      final write = widget.firestore.updateChildProfile(
        widget.parentUid,
        widget.childId,
        name: name,
        avatar: _avatar,
        age: _age,
      );
      unawaited(write.then<void>((_) {}, onError: (Object _) {}));
      await write.timeout(widget.saveTimeout);
    } on TimeoutException {
      savedOnline = false;
    } on FirebaseException {
      savedOnline = false;
    } catch (_) {
      savedOnline = false;
    }
    await widget.store.applyProfileEdit(
      widget.childId,
      name: name,
      avatar: _avatar,
      age: _age,
      parentUid: widget.parentUid,
      queueForSync: !savedOnline,
    );
    if (!savedOnline) {
      messenger.showSnackBar(
        const SnackBar(content: Text(editSavedOfflineMessage)),
      );
    }
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final avatars = [
      if (!childAvatarChoices.contains(widget.avatar)) widget.avatar,
      ...childAvatarChoices,
    ];
    const pink = Color(0xFFFF6FA5);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit learner')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _name,
                    maxLength: 20,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(20),
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'Nickname',
                      helperText:
                          "Please use a nickname, not your child's real name.",
                      prefixIcon: Icon(Icons.person_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Avatar',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final avatar in avatars)
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: InkWell(
                            key: Key('edit-avatar-$avatar'),
                            onTap: () => setState(() => _avatar = avatar),
                            borderRadius: BorderRadius.circular(18),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: avatar == _avatar
                                    ? const Color(0xFFFFE1ED)
                                    : Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: avatar == _avatar
                                      ? pink
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Center(child: EmojiGlyph(avatar, 36)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Age',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Age decides which activities come next after one is finished.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final age in childAgeChoices)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              key: Key('edit-age-$age'),
                              onTap: () => setState(() => _age = age),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                constraints:
                                    const BoxConstraints(minHeight: 52),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: age == _age
                                      ? const Color(0xFFFFE1ED)
                                      : Colors.black.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        age == _age ? pink : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  '$age',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color:
                                        age == _age ? pink : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _busy ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _busy ? null : _save,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: Text(_busy ? 'Saving…' : 'Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
