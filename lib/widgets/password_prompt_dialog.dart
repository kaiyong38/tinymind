import 'package:flutter/material.dart';

/// Asks for the account password on a single row, so the field and buttons
/// stay visible in landscape with the keyboard open. Narrow screens put the
/// buttons on a second row. Pops with the typed password, or null on Cancel.
///
/// Owns its text controller, so the controller lives until the dialog has
/// finished closing.
class PasswordPromptDialog extends StatefulWidget {
  const PasswordPromptDialog({required this.labelText, super.key});

  final String labelText;

  @override
  State<PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<PasswordPromptDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text);

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: _controller,
      obscureText: true,
      autofocus: true,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: widget.labelText,
        isDense: true,
      ),
      onSubmitted: (_) => _submit(),
    );
    final cancel = TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Cancel'),
    );
    final proceed = FilledButton(
      onPressed: _submit,
      child: const Text('Continue'),
    );
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 480) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    field,
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [cancel, const SizedBox(width: 4), proceed],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: field),
                  const SizedBox(width: 8),
                  cancel,
                  const SizedBox(width: 4),
                  proceed,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
