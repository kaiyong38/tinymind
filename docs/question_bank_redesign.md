# TinyMind question bank redesign

This is a staged proposal. Only Shapes (36 questions) is specified in this
review stage; Colors, Numbers, and Letters rows will be added in that order
after the preceding world's proposal is confirmed. No question-bank code is
changed before its world is approved.

## Shapes — 36 questions

`PlayType`: 看和听 / 找一样的 / 说名字 / 生活中的物品 / 概念.
`Cue` describes the proposed left-card illustration. Correct choices are
marked `✓`. Number marks on side/corner-count cues are static, not animated.
The theme activities `shapes_05`, `shapes_10`, and `shapes_11` intentionally
repeat their play type; their prompts, cues, and correct answers vary.

| Activity | Q | PlayType | Current prompt | New short prompt | Cue | Options (correct marked) | Original correct answer | Answer change reason | spokenText |
|---|---:|---|---|---|---|---|---|---|---|
| shapes_01 | 1 | 看和听 | Tap the circle | Circle | 蓝色圆形 | Circle ✓ / square / triangle | circle | — | This is a circle. It is round like a wheel. |
| shapes_01 | 2 | 找一样的 | Tap the circle | Match shape | 深灰圆形剪影 | square / circle ✓ / triangle | circle | — | Find the shape that matches this circle. |
| shapes_01 | 3 | 生活中的物品 | Which one is round like a circle? | Which looks round? | 大圆形 | Gift（方）/ Tent（三角）/ Ball ✓（圆） | Ball | — | Which object is round like this circle? |
| shapes_02 | 1 | 看和听 | Tap the square | Square | 橙色正方形 | triangle / Square ✓ / circle | square | — | This is a square. It has four equal sides. |
| shapes_02 | 2 | 找一样的 | Tap the square | Match shape | 深灰正方形剪影 | circle / triangle / square ✓ | square | — | Find the shape that matches this square. |
| shapes_02 | 3 | 生活中的物品 | Which one looks like a square? | Which looks square? | 大正方形 | Gift ✓（方）/ Cookie（圆）/ Pizza slice（三角） | Gift | — | Which object looks like this square? |
| shapes_03 | 1 | 看和听 | Tap the triangle | Triangle | 绿色三角形 | star / circle / Triangle ✓ | triangle | — | This is a triangle. It has three sides. |
| shapes_03 | 2 | 找一样的 | Tap the triangle | Match shape | 深灰三角形剪影 | triangle ✓ / square / circle | triangle | — | Find the shape that matches this triangle. |
| shapes_03 | 3 | 生活中的物品 | Which one looks like a triangle? | Which looks pointy? | 大三角形 | Cookie（圆）/ Pizza slice ✓（三角）/ Gift（方） | Pizza slice | — | Which object is pointy like this triangle? |
| shapes_04 | 1 | 看和听 | Tap the star | Star | 黄色星形 | Star ✓ / circle / square | star | — | This is a star. It has pointy tips. |
| shapes_04 | 2 | 找一样的 | Which shape twinkles in the night sky? | Match shape | 深灰星形剪影 | triangle / star ✓ / circle | star | — | Find the shape that matches this star. |
| shapes_04 | 3 | 生活中的物品 | Which one is a star? | Twinkles? | 闪光 ✨ | Moon / Cloud / Star ✓ | Star | — | Which one twinkles in the night sky? |
| shapes_05 | 1 | 看和听 | Tap the ball ⚽ | Which is round? | 彩色圆形 | Gift（方）/ Ball ✓（圆）/ Pizza slice（三角） | Ball | — | This circle is round. Which object is round too? |
| shapes_05 | 2 | 概念 | Tap the cookie 🍪 | Find round! | 深灰圆形剪影 | Tent（三角）/ Box（方）/ Cookie ✓（圆） | Cookie | — | Which object is round like this circle? |
| shapes_05 | 3 | 生活中的物品 | Tap the gift 🎁 | Round one? | 虚线圆形轮廓 | Gift（方）/ Tent（三角）/ Orange ✓（圆） | Gift | Change Gift to Orange: the three target answers are the required round objects (ball, cookie, orange). |
| shapes_06 | 1 | 看和听 | Which one is shaped like a square? | Which is square? | 正方形 cue | Ball（圆）/ Pizza slice（三角）/ Gift ✓（方） | Gift | — | Which object has a square shape? |
| shapes_06 | 2 | 找一样的 | Which one has corners? | Looks like this? | 深灰正方形剪影 | Box ✓（方）/ Orange（圆）/ Moon（圆） | Box | — | Which object matches this square shape? |
| shapes_06 | 3 | 说名字 | Which one looks like a square? | Frame shape? | 画框 🖼️ | circle（圆）/ square ✓（方）/ triangle（三角） | Picture frame | Change Picture frame to square: Q3 now reverses the direction, using the frame cue and shape choices. |
| shapes_07 | 1 | 看和听 | Which one is pointy like a triangle? | Which is pointy? | 三角形 cue | Pizza slice ✓（三角）/ Ball（圆）/ Cookie（圆） | Pizza slice | — | Which object has a pointy shape? |
| shapes_07 | 2 | 找一样的 | Which one is like a triangle? | Looks like this? | 深灰三角形剪影 | Orange（圆）/ Tent ✓（三角）/ Moon（圆） | Tent | — | Which object matches this pointy shape? |
| shapes_07 | 3 | 说名字 | Which one is a triangle? | Which shape fits? | 山峰 ⛰️（真机若不明显，再换 🚩） | circle（圆）/ square（方）/ triangle ✓（三角） | triangle | — | Which shape has this pointy outline? |
| shapes_08 | 1 | 看和听 | Which one is a star shape? | Find the star | AnswerVisual.shape 星形 | circle / star ✓ / square | star shape | — | Find the star shape. |
| shapes_08 | 2 | 找一样的 | Which one is a star? | Match star | 深灰星形剪影 | Cookie 🍪 / Box 📦 / Glowing star 🌟 ✓ | Glowing star | — | Find the picture that matches this star silhouette. |
| shapes_08 | 3 | 生活中的物品 | Which one shines in the night sky? | Night sky? | 深色夜空场景，含月亮但不含星星 | Star ⭐ ✓ / Pizza slice / Gift | Star | — | Which picture belongs in this night sky? |
| shapes_09 | 1 | 看和听 | How many sides does a triangle have? | How many sides? | 三角形三边静态编号 1、2、3 | 2 / 4 / 3 ✓ | Triangle (3) | — | How many sides does a triangle have? |
| shapes_09 | 2 | 概念 | How many sides does a square have? | How many sides? | 正方形四边交替着色，不编号 | 4 ✓ / 3 / 5 | Square (4) | — | How many sides does a square have? |
| shapes_09 | 3 | 说名字 | How many straight sides does a circle have? | How many corners? | 正方形四角圆点，不编号 | 3 / 5 / 4 ✓ | Circle (0) | Replace the invalid circle-side count with the requested square-corner count. | How many corners does a square have? |
| shapes_10 | 1 | 概念 | 🔴 🔴 🔺 / Which shape is different? | Odd one out? | App 形状组件：蓝色三角 / 蓝色圆 / 蓝色圆；不高亮，不同项在左 | triangle ✓ / circle / square | triangle | — | Which shape is different in this row? |
| shapes_10 | 2 | 概念 | ⬛ 🔺 ⬛ / Which shape is different? | Odd one out? | App 形状组件：蓝色方 / 蓝色三角 / 蓝色方；不高亮，不同项在中 | square / triangle ✓ / circle | triangle | — | Which shape is different in this row? |
| shapes_10 | 3 | 概念 | 🔺 🔺 🔴 / Which shape is different? | Odd one out? | App 形状组件：蓝色三角 / 蓝色三角 / 蓝色圆；不高亮，不同项在右 | triangle / square / circle ✓ | circle | — | Which shape is different in this row? |
| shapes_11 | 1 | 找一样的 | Tap the same shape / 🔺 | Match triangle | 红色三角形目标；选项形状组件颜色保持原样（绿色三角形） | circle / triangle ✓ / square | triangle | — | Find the triangle that matches the target. |
| shapes_11 | 2 | 找一样的 | Tap the same shape / 🔴 | Match circle | 红色圆形目标；选项形状组件颜色保持原样（蓝色圆形） | square / triangle / circle ✓ | circle | — | Find the circle that matches the target. |
| shapes_11 | 3 | 找一样的 | Tap the same shape / ⬛ | Match square | 红色正方形目标；选项形状组件颜色保持原样（橙色正方形） | square ✓ / circle / triangle | square | — | Find the square that matches the target. |
| shapes_12 | 1 | 看和听 | Which shape has 4 corners? | 4 corners? | 四个独立角点符号，无形状轮廓 | circle / triangle / square ✓ | square | — | Which shape has four corners? |
| shapes_12 | 2 | 概念 | Which shape rolls the best? | Rolls best? | 斜坡加滚动箭头，无形状图案 | circle ✓ / square / triangle | circle | — | Which shape rolls smoothly down a slope? |
| shapes_12 | 3 | 说名字 | Which shape has 3 sides? | 3 sides? | 三条独立边线记号，无形状轮廓 | square / triangle ✓ / circle | triangle | — | Which shape has three sides? |

### Shapes cue and answer notes

- `shapes_01`–`shapes_03` Q3 use a drawn shape cue; answer choices remain the
  existing everyday-object pictures.
- `shapes_04` Q3 uses a sparkle cue. `shapes_08` Q3 intentionally uses a
  night-sky scene with a moon while retaining the Star / Pizza slice / Gift choices;
  the moon is neither the Star option nor the correct answer.
- `shapes_05` keeps its required circle/object theme and varies cue rendering,
  prompt, and correct object across its three questions.
- `shapes_06` and `shapes_07` use object-finding, silhouette matching, then
  reverse object-to-shape identification. `shapes_08` Q3 follows its specific
  night-scene requirement instead.
- `shapes_09` static number labels identify sides/corners; no animation.
- `shapes_10` never highlights the odd shape in the question cue. Feedback
  highlights it only after an answer. All cue shapes use the same App blue;
  the unique position is left, middle, then right.
- Cue/option identity checks compare exact `identityKey`s: an emoji string, or
  a shape name plus its representation type. They do not infer object geometry,
  so a shape-to-object or object-to-shape analogy is allowed. For those analogy
  questions, every distractor is separately reviewed for an unmistakably
  different shape; the table labels each distractor's shape explicitly.
- Identity matching is exempt for 看和听 and 找一样的. Find-the-difference and
  concept questions are also exempt because their cue must show the target.
- A repeated correct answer within an activity is permitted unless the full
  `(prompt, cue, correct answer)` tuple is repeated.
- `shapes_08` intentionally uses different correct-option identities in its
  three questions: a drawn star shape, glowing-star emoji, and star-picture
  emoji. `shapes_11` targets intentionally use different colors from the
  corresponding shape choices; the match is by shape, not color.
