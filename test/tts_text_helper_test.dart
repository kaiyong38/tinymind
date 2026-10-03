import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/services/tts_text_helper.dart';

void main() {
  group('TtsTextHelper.clean', () {
    test('removes decorative emoji from ordinary prompts', () {
      expect(
        TtsTextHelper.clean('Tap the letter that matches 🍎'),
        'Tap the letter that matches',
      );
    });

    test('converts count picture questions to number words and correct nouns',
        () {
      expect(
        TtsTextHelper.clean('🎈🎈🎈🎈\nHow many balloons?'),
        'four balloons',
      );
      expect(
        TtsTextHelper.clean('🎈\nHow many balloons?'),
        'one balloon',
      );
      expect(
        TtsTextHelper.clean('🐟🐟🐟🐟🐟\n🐟🐟🐟🐟\nHow many fish?'),
        'nine fish',
      );
    });

    test('converts letter sound spellings into phonetic speech', () {
      expect(
          TtsTextHelper.clean('Say it with me: Aaa!'), 'Say it with me: ah!');
      expect(
        TtsTextHelper.clean('Listen for the first sound: Buh!'),
        'Listen for the first sound: buh!',
      );
    });

    test('reads equations as words and omits visual emoji groups', () {
      expect(
        TtsTextHelper.clean('🍎🍎 + 🍎\n2 + 1 = ?'),
        'two plus one equals what?',
      );
    });

    test('removes shape-only decorations', () {
      expect(
        TtsTextHelper.clean('🔴 🔴 🔺\nWhich shape is different?'),
        'Which shape is different?',
      );
    });
  });
}
