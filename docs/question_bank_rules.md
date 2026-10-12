# TinyMind question bank rules
1. Audience: children under 6 (ages 3-6). Pictures, symbols and voice come first; screen text is minimal.
2. Text limits: prompt at most 3 words (numerals and symbols do not count; any exception needs approval, maximum 5); hint at most 6 words; teach at most 8 words. The intro (teach) screen speaks the teach text shown on it. The first question's spokenText is the instruction only, never the intro sentence again. Every spokenText is a full sentence with number words and no emoji.
3. For non-teach questions, the prompt and spokenText never name the correct answer or show its number (exempt: lookListen and findSame).
4. The cue never equals the correct option (identityKey), except for lookListen and findSame. Odd-one-out sets are exempt. Shape-to-object analogies are allowed; every distractor must be clearly different.
5. Each activity has 3 questions with 3 different play types. Theme activities (counting, adding, subtracting) may repeat the play type but must vary the cue and the answer. No two questions in an activity share the same (prompt, cue, correct answer).
6. Pictures: only emoji from Unicode 12 or earlier (Android 10). Avoid ambiguous pictures (full moon, ribbon, crystal ball, white cloud). Do not reuse a correct-answer object across activities of one world; distractor pictures may recur. Always render emoji with EmojiGlyph, never a bare Text.
7. Layout: the question card shows the cue and the short prompt only. There is no read-aloud button in the card, and none in the page header. Tapping the whole question card (or the intro bubble) repeats the question; the card and the bubble each show one small speaker icon as a hint only. Answer tiles are sized by the existing code; new visuals must fill the tile with FittedBox and must not overflow at 568x320, 640x360, 732x412 with text scale up to 1.3.
   On larger displays, the app uses a 640 × 400 logical-pixel stage scaled
   uniformly to fit the window (up to 3×); phone-sized layouts are unchanged.
8. Data integrity: keep activity ids, section order, minAge, 3 options per question, correct answerIndex. Arithmetic and count invariants are covered by tests.
9. Process: first write the proposal rows into docs/question_bank_redesign.md (activity, Q, playType, current prompt, new short prompt, cue, options with the correct one marked, original correct answer, change reason, spokenText) and stop for review; implement only after approval.
10. Do not add dependencies and do not touch the audio-focus configuration.
11. Spoken text avoids interjections and sound words (ooh, hmm, woohoo, yay,
    hooray, whoa); praise names what the child did, not how smart they are.
12. The activity emoji (shown in the quiz header and on the library card)
    must not equal the correct picture of any question in that activity,
    except the first teaching question.
