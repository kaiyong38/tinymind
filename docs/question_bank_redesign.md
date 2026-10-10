# TinyMind question bank redesign

Shapes (36 questions), Colors (36 questions), Numbers (60 questions), and
Letters (78 questions) are specified and implemented.

## Shapes — 36 questions

`PlayType`: 看和听 / 找一样的 / 说名字 / 生活中的物品 / 概念.
`Cue` describes the proposed left-card illustration. Correct choices are
marked `✓`. Number marks on side/corner-count cues are static, not animated.
The theme activities `shapes_05`, `shapes_10`, and `shapes_11` intentionally
repeat their play type; their prompts, cues, and correct answers vary.

| Activity | Q | PlayType | Current prompt | New short prompt | Cue | Options (correct marked) | Original correct answer | Answer change reason | spokenText |
|---|---:|---|---|---|---|---|---|---|---|
| shapes_01 | 1 | 看和听 | Tap the circle | Circle | 蓝色圆形 | Circle ✓ / square / triangle | circle | — | Tap the circle. |
| shapes_01 | 2 | 找一样的 | Tap the circle | Match shape | 深灰圆形剪影 | square / circle ✓ / triangle | circle | — | Find the shape that matches this circle. |
| shapes_01 | 3 | 生活中的物品 | Which one is round like a circle? | Which looks round? | 大圆形 | Gift（方）/ Tent（三角）/ Donut ✓（圆） | Donut | 用 Donut 替换另一个活动已用作正确图片的 Ball。 | Which object is round like this circle? |
| shapes_02 | 1 | 看和听 | Tap the square | Square | 橙色正方形 | triangle / Square ✓ / circle | square | — | Tap the square. |
| shapes_02 | 2 | 找一样的 | Tap the square | Match shape | 深灰正方形剪影 | circle / triangle / square ✓ | square | — | Find the shape that matches this square. |
| shapes_02 | 3 | 生活中的物品 | Which one looks like a square? | Which looks square? | 大正方形 | Picture frame ✓（方）/ Cookie（圆）/ Pizza slice（三角） | Picture frame | 用 Picture frame 替换另一个活动已用作正确图片的 Gift。 | Which object looks like this square? |
| shapes_03 | 1 | 看和听 | Tap the triangle | Triangle | 绿色三角形 | star / circle / Triangle ✓ | triangle | — | Tap the triangle. |
| shapes_03 | 2 | 找一样的 | Tap the triangle | Match shape | 深灰三角形剪影 | triangle ✓ / square / circle | triangle | — | Find the shape that matches this triangle. |
| shapes_03 | 3 | 生活中的物品 | Which one looks like a triangle? | Which looks pointy? | 大三角形 | Cookie（圆）/ Sandwich ✓（三角）/ Gift（方） | Sandwich | 用 Sandwich 替换另一个活动已用作正确图片的 Pizza slice。 | Which object is pointy like this triangle? |
| shapes_04 | 1 | 看和听 | Tap the star | Star | 黄色星形 | Star ✓ / circle / square | star | — | Tap the star. |
| shapes_04 | 2 | 找一样的 | Which shape twinkles in the night sky? | Match shape | 深灰星形剪影 | triangle / star ✓ / circle | star | — | Find the shape that matches this star. |
| shapes_04 | 3 | 生活中的物品 | Which one is a star? | Twinkles? | 闪光 ✨ | Rainbow / Cloud / Fireworks ✓ | Fireworks | 用 Fireworks 替换另一个活动已用作正确图片的 Star。 | Which one twinkles in the night sky? |
| shapes_05 | 1 | 看和听 | Tap the ball ⚽ | Which is round? | 彩色圆形 | Gift（方）/ Ball ✓（圆）/ Pizza slice（三角） | Ball | — | Which object is round like this circle? |
| shapes_05 | 2 | 概念 | Tap the cookie 🍪 | Find round! | 深灰圆形剪影 | Tent（三角）/ Box（方）/ Cookie ✓（圆） | Cookie | — | Which object is round like this circle? |
| shapes_05 | 3 | 生活中的物品 | Tap the gift 🎁 | Round one? | 虚线圆形轮廓 | Gift（方）/ Tent（三角）/ Orange ✓（圆） | Gift | Change Gift to Orange: the three target answers are the required round objects (ball, cookie, orange). |
| shapes_06 | 1 | 看和听 | Which one is shaped like a square? | Which is square? | 正方形 cue | Ball（圆）/ Pizza slice（三角）/ Gift ✓（方） | Gift | — | Which object has a square shape? |
| shapes_06 | 2 | 找一样的 | Which one has corners? | Looks like this? | 深灰正方形剪影 | Box ✓（方）/ Orange（圆）/ Cookie（圆） | Box | — | Which object matches this square shape? |
| shapes_06 | 3 | 说名字 | Which one looks like a square? | Frame shape? | 画框 🖼️ | circle（圆）/ square ✓（方）/ triangle（三角） | Picture frame | Change Picture frame to square: Q3 now reverses the direction, using the frame cue and shape choices. |
| shapes_07 | 1 | 看和听 | Which one is pointy like a triangle? | Which is pointy? | 三角形 cue | Pizza slice ✓（三角）/ Ball（圆）/ Cookie（圆） | Pizza slice | — | Which object has a pointy shape? |
| shapes_07 | 2 | 找一样的 | Which one is like a triangle? | Looks like this? | 深灰三角形剪影 | Orange（圆）/ Tent ✓（三角）/ Ball（圆） | Tent | — | Which object matches this pointy shape? |
| shapes_07 | 3 | 说名字 | Which one is a triangle? | Which shape fits? | 山峰 ⛰️（真机若不明显，再换 🚩） | circle（圆）/ square（方）/ triangle ✓（三角） | triangle | — | Which shape has this pointy outline? |
| shapes_08 | 1 | 看和听 | Which one is a star shape? | Find the star | AnswerVisual.shape 星形 | circle / star ✓ / square | star shape | — | Find the star shape. |
| shapes_08 | 2 | 找一样的 | Which one is a star? | Match star | 深灰星形剪影 | Cookie 🍪 / Box 📦 / Glowing star 🌟 ✓ | Glowing star | — | Find the picture that matches this star silhouette. |
| shapes_08 | 3 | 生活中的物品 | Which one shines in the night sky? | Night sky? | 深色夜空场景，含月亮但不含星星 | Star ⭐ ✓ / Pizza slice / Gift | Star | — | Which picture belongs in this night sky? |
| shapes_09 | 1 | 看和听 | How many sides does a triangle have? | How many sides? | 三角形三边顺时针编号 1、2、3（从左边开始，数字在边外侧的小圆里） | 2 / 4 / 3 ✓ | Triangle (3) | — | How many sides does a triangle have? |
| shapes_09 | 2 | 概念 | How many sides does a square have? | How many sides? | 正方形四边各用不同颜色，不编号 | 4 ✓ / 3 / 5 | Square (4) | — | How many sides does a square have? |
| shapes_09 | 3 | 说名字 | How many straight sides does a circle have? | How many corners? | 正方形四角圆点，不编号 | 3 / 5 / 4 ✓ | Circle (0) | Replace the invalid circle-side count with the requested square-corner count. | How many corners does a square have? |
| shapes_10 | 1 | 概念 | 🔴 🔴 🔺 / Which shape is different? | Odd one out? | 三角（绿）/ 圆（蓝）/ 圆（蓝）；不同项在左，用自己的颜色，不高亮 | triangle ✓ / circle / square | triangle | — | Which shape is different in this row? |
| shapes_10 | 2 | 概念 | ⬛ 🔺 ⬛ / Which shape is different? | Odd one out? | 方（橙）/ 三角（绿）/ 方（橙）；不同项在中，用自己的颜色，不高亮 | square / triangle ✓ / circle | triangle | — | Which shape is different in this row? |
| shapes_10 | 3 | 概念 | 🔺 🔺 🔴 / Which shape is different? | Odd one out? | 三角（绿）/ 三角（绿）/ 圆（蓝）；不同项在右，用自己的颜色，不高亮 | triangle / square / circle ✓ | circle | — | Which shape is different in this row? |
| shapes_11 | 1 | 找一样的 | Tap the same shape / 🔺 | Match triangle | 红色三角形目标；选项形状组件颜色保持原样（绿色三角形） | circle / triangle ✓ / square | triangle | — | Find the triangle that matches the target. |
| shapes_11 | 2 | 找一样的 | Tap the same shape / 🔴 | Match circle | 红色圆形目标；选项形状组件颜色保持原样（蓝色圆形） | square / triangle / circle ✓ | circle | — | Find the circle that matches the target. |
| shapes_11 | 3 | 找一样的 | Tap the same shape / ⬛ | Match square | 红色正方形目标；选项形状组件颜色保持原样（橙色正方形） | square ✓ / circle / triangle | square | — | Find the square that matches the target. |
| shapes_12 | 1 | 看和听 | Which shape has 4 corners? | 4 corners? | 大数字 4；选项形状上标出红色角点（圆形没有点） | circle / triangle / square ✓ | square | — | Which shape has four corners? |
| shapes_12 | 2 | 概念 | Which shape rolls down the hill? | Rolls down? | 满幅场景：浅绿色地面、浅棕色直角斜坡、深色下坡箭头与三条速度线，右侧地面延伸虚线；不含形状物体 | circle ✓ / square / triangle | circle | — | Which shape rolls down the hill? |
| shapes_12 | 3 | 说名字 | Which shape has 3 sides? | 3 sides? | 大数字 3；选项形状的每条边用不同颜色（圆形只有一条灰色轮廓） | square / triangle ✓ / circle | triangle | — | Which shape has three sides? |

### Shapes cue and answer notes

- `shapes_03` uses the downward triangle badge so it does not duplicate the
  triangle badge used by `shapes_07`.
- `colors_09`–`colors_11` use distinct paint-tool badges so mixing activities
  do not repeat the basic-color activity badges.
- `shapes_01`–`shapes_03` Q3 use a drawn shape cue; answer choices remain the
  existing everyday-object pictures.
- `shapes_04` Q3 uses a sparkle cue and a fireworks picture. `shapes_08` Q3 intentionally uses a
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

### Changes after device testing (October 2026)

- The intro screen of an activity now reads the text shown on it. The first question's `spokenText` is the instruction only ("Tap the circle."), so the same sentence is not read twice.
- There is no read-aloud button in the question card or the page header. Tapping the whole question card (or the intro bubble) repeats the question; the card and the bubble each show one small speaker icon as a hint only, with the semantic label "Hear the question again".
- Activity cards in the library show a small round number (the activity's position in its world, continuous across sections; semantic label "Activity N") at the top-right. The "N+" age tag moved just below it.
- Activity emojis are also shown in the quiz header. To avoid revealing a
  non-teaching answer, `letters_x`, `shapes_04`, `shapes_06`, `shapes_07`, and
  `shapes_08` now use 📦, 🌠, 🟦, 🔺, and ✨ respectively. The 📦 on the first
  `letters_x` teaching question is covered by the first-question exception.
- The Moon picture was removed from the answer pictures (Rainbow in shapes_04 Q3, Cookie in shapes_06 Q2, Ball in shapes_07 Q2).
- shapes_10: the odd shape keeps its own color (triangle green, circle blue, square orange) and the row fills the card, so the triangle is no longer squeezed.
- shapes_12 (option A): the card shows only a big number; the answer shapes carry the red corner dots or the colored sides, so children count real shapes.
- shapes_09: the sides are numbered clockwise from the left, with the number in a small circle outside each side.
- Answer tiles are larger, and the question cue uses the whole card.
- "Next" on the result page goes to the next activity in order for the child's age instead of the first unfinished one.
- The activity list refreshes its stars whenever progress changes (it used to refresh only once when several activities were chained with "Next").

## Colors — 36 questions

Colors keep the same rules as Shapes: prompts use at most three words, the full sentence is spoken, and the correct answer never appears in the prompt or the speech (except in the teaching question). Basic colors (colors_01–08) use *name → swatch*, *swatch → picture*, *picture → swatch*. Mixing (colors_09–11) and the rainbow (colors_12) are 5+ activities that show the idea as color swatches instead of sentences. Color-friendly mode (patterns and names) still applies to every swatch option and swatch cue.

| Activity | Q | PlayType | Current prompt | New short prompt | Cue | Options (correct marked) | Original correct answer | Answer change reason | spokenText |
|---|---:|---|---|---|---|---|---|---|---|
| colors_01 | 1 | 看和听 | Tap the color RED | Tap the color | 颜色名大字（不放色块）：RED | Red ✓ / Blue / Orange | Red | — | Tap the color red. |
| colors_01 | 2 | 生活中的物品 | Which one is red? | Which is red? | 大色块：Red | Wave / Apple ✓ / Carrot | Apple | — | Which picture is red? |
| colors_01 | 3 | 生活中的物品 | Tap the color of a strawberry 🍓 | What color? | 物品 🍓 | Yellow / Pink / Red ✓ | Red | — | What color is a strawberry? |
| colors_02 | 1 | 看和听 | Tap the color BLUE | Tap the color | 颜色名大字（不放色块）：BLUE | Yellow / Blue ✓ / Purple | Blue | — | Tap the color blue. |
| colors_02 | 2 | 生活中的物品 | Which one is blue? | Which is blue? | 大色块：Blue | Banana / Apple / Water drop ✓ | Water drop | — | Which picture is blue? |
| colors_02 | 3 | 生活中的物品 | Tap the color of the sky ☁️ | What color? | 物品 🐳 | Blue ✓ / Green / Brown | Blue | — | What color is a whale? |
| colors_03 | 1 | 看和听 | Tap the color YELLOW | Tap the color | 颜色名大字（不放色块）：YELLOW | Green / Pink / Yellow ✓ | Yellow | — | Tap the color yellow. |
| colors_03 | 2 | 生活中的物品 | Which one is yellow? | Which is yellow? | 大色块：Yellow | Chick ✓ / Frog / Pig | Chick | — | Which picture is yellow? |
| colors_03 | 3 | 生活中的物品 | Tap the color of a banana 🍌 | What color? | 物品 🍌 | Orange / Yellow ✓ / Red | Yellow | — | What color is a banana? |
| colors_04 | 1 | 看和听 | Tap the color GREEN | Tap the color | 颜色名大字（不放色块）：GREEN | Green ✓ / Orange / Brown | Green | — | Tap the color green. |
| colors_04 | 2 | 生活中的物品 | Which one is green? | Which is green? | 大色块：Green | Orange / Frog ✓ / Chocolate | Frog | — | Which picture is green? |
| colors_04 | 3 | 生活中的物品 | Tap the color of grass 🌿 | What color? | 物品 🌿 | Purple / Blue / Green ✓ | Green | — | What color is the grass? |
| colors_05 | 1 | 看和听 | Tap the color ORANGE | Tap the color | 颜色名大字（不放色块）：ORANGE | Red / Orange ✓ / Green | Orange | — | Tap the color orange. |
| colors_05 | 2 | 生活中的物品 | Which one is orange? | Which is orange? | 大色块：Orange | Apple / Tree / Fox ✓ | Orange | Orange 🍊 as a picture option is confusing next to the color name, so the answer is now the orange Fox 🦊. | Which picture is orange? |
| colors_05 | 3 | 生活中的物品 | Tap the color of a carrot 🥕 | What color? | 物品 🥕 | Orange ✓ / Blue / Pink | Orange | — | What color is a carrot? |
| colors_06 | 1 | 看和听 | Tap the color PURPLE | Tap the color | 颜色名大字（不放色块）：PURPLE | Blue / Orange / Purple ✓ | Purple | — | Tap the color purple. |
| colors_06 | 2 | 生活中的物品 | Which one is purple? | Which is purple? | 大色块：Purple | Crystal ball ✓ / Wave / Carrot | Crystal ball | — | Which picture is purple? |
| colors_06 | 3 | 生活中的物品 | Tap the color of grapes 🍇 | What color? | 物品 🍇 | Yellow / Purple ✓ / Brown | Purple | — | What color are grapes? |
| colors_07 | 1 | 看和听 | Tap the color PINK | Tap the color | 颜色名大字（不放色块）：PINK | Pink ✓ / Yellow / Purple | Pink | — | Tap the color pink. |
| colors_07 | 2 | 生活中的物品 | Which one is pink? | Which is pink? | 大色块：Pink | Banana / Flamingo ✓ / Frog | Ribbon | The ribbon 🎀 looked red on a real phone, so the answer is now the pink Flamingo 🦩. | Which picture is pink? |
| colors_07 | 3 | 生活中的物品 | Tap the color of a pig 🐷 | What color? | 物品 🐷 | Green / Red / Pink ✓ | Pink | — | What color is a pig? |
| colors_08 | 1 | 看和听 | Tap the color BROWN | Tap the color | 颜色名大字（不放色块）：BROWN | Green / Brown ✓ / Pink | Brown | — | Tap the color brown. |
| colors_08 | 2 | 生活中的物品 | Which one is brown? | Which is brown? | 大色块：Brown | Frog / Pig / Bear ✓ | Bear | — | Which picture is brown? |
| colors_08 | 3 | 生活中的物品 | Tap the color of a teddy bear 🧸 | What color? | 物品 🧸 | Brown ✓ / Orange / Blue | Brown | — | What color is a teddy bear? |
| colors_09 | 1 | 看和听 | What color do red and yellow make? | What color? | 色块算式：Red + Yellow = ? | Green / Purple / Orange ✓ | Orange | — | What color do red and yellow make? |
| colors_09 | 2 | 概念 | Which two colors make orange? | Make orange? | 大色块：Orange | Red + Yellow ✓ / Blue + Yellow / Red + Blue | Red + Yellow | Shown as paint mixing: two-color option cards instead of text options. | Which two colors make orange? |
| colors_09 | 3 | 生活中的物品 | Tap the color of a carrot 🥕 | What color? | 物品 🎃 | Blue / Orange ✓ / Pink | Orange | — | What color is a pumpkin? |
| colors_10 | 1 | 看和听 | What color do blue and yellow make? | What color? | 色块算式：Blue + Yellow = ? | Green ✓ / Orange / Pink | Green | — | What color do blue and yellow make? |
| colors_10 | 2 | 概念 | Which two colors make green? | Make green? | 大色块：Green | Red + Yellow / Blue + Yellow ✓ / Red + Blue | Blue + Yellow | Same as colors_09. | Which two colors make green? |
| colors_10 | 3 | 生活中的物品 | Tap the color of a frog 🐸 | What color? | 物品 🐢 | Purple / Red / Green ✓ | Green | — | What color is a turtle? |
| colors_11 | 1 | 看和听 | What color do red and blue make? | What color? | 色块算式：Red + Blue = ? | Green / Purple ✓ / Brown | Purple | — | What color do red and blue make? |
| colors_11 | 2 | 概念 | Which two colors make purple? | Make purple? | 大色块：Purple | Blue + Yellow / Red + Yellow / Red + Blue ✓ | Red + Blue | Same as colors_09. | Which two colors make purple? |
| colors_11 | 3 | 生活中的物品 | Tap the color of grapes 🍇 | What color? | 物品 💜 | Purple ✓ / Yellow / Orange | Purple | — | What color is the heart? |
| colors_12 | 1 | 看和听 | Which color comes first in the rainbow? 🌈 | First color? | 彩虹条（红橙黄绿蓝紫），缺「红」带 ? | Green / Blue / Red ✓ | Red | — | Which color is first in the rainbow? |
| colors_12 | 2 | 概念 | Tap the color that is NOT in a rainbow | What is next? | 彩虹条（红橙黄绿蓝紫），缺「绿」带 ? | Blue / Green ✓ / Red | Brown | The old NOT-in-the-rainbow question is replaced by "which color comes after yellow". | Which color comes after yellow? |
| colors_12 | 3 | 概念 | Which color is between red and yellow in a rainbow? | What is missing? | 彩虹条（红橙黄绿蓝紫），缺「橙」带 ? | Green / Orange ✓ / Purple | Orange | Same band-order idea, now shown on the rainbow. | Which color is between red and yellow? |

### Colors notes

- Object cues are all different across Colors: strawberry, whale (replaces the white cloud for blue), banana, grass, carrot, grapes, pig, teddy bear, pumpkin, turtle, purple heart.
- colors_02 Q2 uses Apple instead of the crystal ball; colors_07 Q2 uses a Flamingo instead of the ribbon.
- Mixing options (colors_09–11 Q2) are drawn as two large color dots side by side, labelled Red + Yellow, Blue + Yellow, Red + Blue.
- The rainbow uses only the app palette (red, orange, yellow, green, blue, purple); the missing band is grey with a ? badge. A test checks the answer against that band's color.

## Numbers — 60 questions (implemented)

The rows below preserve all Numbers activity ids, section order, ages, option
counts, and correct `answerIndex` positions. The `Original correct answer`
column records the current answer; a changed target is called out explicitly.
Each activity uses three different planned play types: Q1 看和听, Q2 找一样的
or 概念, Q3 说名字. Thus none of the 20 activities repeats its play type.
Counting, addition, and subtraction vary their cue and count/problem within
each activity. Repeated correct answers are allowed when the full
`(prompt, cue, correct answer)` tuple differs; numbers_13 keeps the original
2+3, 4+1, and 1+3 problems as confirmed.

Number-answer distractors are distinct values one or two away from the target,
never negative; each row keeps its existing correct-option index. Counting
Q2 in numbers_01–05 uses dot-card options with those same nearby counts.
Item cues use one object per activity: balloons, apples, stars, ducks, cars,
flowers, fish, cookies, ladybugs, teddy bears, lemons, frogs, balls, trains,
and carrots. No object repeats across these Numbers activities.

For numbers_06, numbers_08 and numbers_10 Q2, scattered-item positions use a
fixed normalized slot map computed against the cue's actual width and height:
P1 (0.14, 0.28), P2 (0.38, 0.20), P3 (0.62, 0.32), P4 (0.86, 0.24),
P5 (0.24, 0.68), P6 (0.50, 0.78), P7 (0.76, 0.64), P8 (0.88, 0.82).
For each count, use the first N slots; never randomize positions. Item size is
at least 28 dp and centers are separated by at least 1.15 item sizes. If a
layout cannot fit these constraints, reduce the scattered count and flag it.
Ordered groups put up to five items in the first row and the remainder below;
numbers_07 Q2 is a 3-by-3 grid and numbers_09 Q2 is two rows of five.

The item-row, equation-picture, and ten-frame cues are new `QuizCue`
types with stable `identityKey`s. The equation-picture cue keeps a gray `= ?`
as part of the equation; the item-row (take-away) and ten-frame cues have no
corner `?` badge. The equation-picture cue places the two emoji groups around
a plus sign; subtraction crosses out the removed items.
Ten-frames draw the known addend as red dots and the unknown one as grey `?`
dots (same look as the grey mystery circle): addition = first addend red, second
addend `?`; subtraction = red dots with the removed ones crossed out;
make-ten = known dots red, every remaining cell `?`; teen number = full first
frame red, second frame `?` dots for the second addend.
`TenFrameCue.filledDots` / `questionDots` expose the counts for tests.

| Activity | Q | PlayType | Current prompt | New short prompt | Cue | Options (correct marked) | Original correct answer | Answer change reason | spokenText | Teach / teachOption |
|---|---:|---|---|---|---|---|---|---|---|---|
| numbers_01 | 1 | 看和听 | 🎈 / How many balloons? | How many? | 有序物品排：1 个 🎈 | 1 ✓ / 2 / 3 | 1 | — | How many balloons? | Let's count balloons! / 1 |
| numbers_01 | 2 | 找一样的 | 🎈🎈 / How many balloons? | Match the count | 有序物品排：2 个 🎈 | 3 点 / 2 点 ✓ / 1 点 | 2 | — | Find the dots that match the balloons. | — |
| numbers_01 | 3 | 说名字 | 🎈🎈🎈 / How many balloons? | Count the group | 有序物品排：3 个 🎈 | 4 / 2 / 3 ✓ | 3 | — | Count the balloons. How many are there? | — |
| numbers_02 | 1 | 看和听 | 🍎🍎 / How many apples? | How many? | 有序物品排：2 个 🍎 | 3 / 2 ✓ / 1 | 2 | — | How many apples? | Let's count apples! / 2 |
| numbers_02 | 2 | 找一样的 | 🍎🍎🍎🍎 / How many apples? | Match the count | 有序物品排：4 个 🍎 | 5 点 / 3 点 / 4 点 ✓ | 4 | — | Find the dots that match the apples. | — |
| numbers_02 | 3 | 说名字 | 🍎🍎🍎 / How many apples? | Count the group | 有序物品排：3 个 🍎 | 3 ✓ / 2 / 4 | 3 | — | Count the apples. How many are there? | — |
| numbers_03 | 1 | 看和听 | ⭐⭐⭐ / How many stars? | How many? | 有序物品排：3 个 ⭐ | 4 / 2 / 3 ✓ | 3 | — | How many stars? | Let's count stars! / 3 |
| numbers_03 | 2 | 找一样的 | ⭐⭐⭐⭐⭐ / How many stars? | Match the count | 有序物品排：5 个 ⭐ | 5 点 ✓ / 4 点 / 6 点 | 5 | — | Find the dots that match the stars. | — |
| numbers_03 | 3 | 说名字 | ⭐⭐⭐⭐ / How many stars? | Count the group | 有序物品排：4 个 ⭐ | 3 / 4 ✓ / 5 | 4 | — | Count the stars. How many are there? | — |
| numbers_04 | 1 | 看和听 | 🦆🦆🦆🦆 / How many ducks? | How many? | 有序物品排：4 个 🦆 | 4 ✓ / 3 / 5 | 4 | — | How many ducks? | Let's count ducks! / 4 |
| numbers_04 | 2 | 找一样的 | 🦆🦆 / How many ducks? | Match the count | 有序物品排：2 个 🦆 | 3 点 / 2 点 ✓ / 1 点 | 2 | — | Find the dots that match the ducks. | — |
| numbers_04 | 3 | 说名字 | 🦆🦆🦆🦆🦆 / How many ducks? | Count the group | 有序物品排：5 个 🦆 | 6 / 4 / 5 ✓ | 5 | — | Count the ducks. How many are there? | — |
| numbers_05 | 1 | 看和听 | 🚗🚗🚗🚗🚗 / How many cars? | How many? | 有序物品排：5 个 🚗 | 4 / 5 ✓ / 6 | 5 | — | How many cars? | Let's count cars! / 5 |
| numbers_05 | 2 | 找一样的 | 🚗🚗🚗 / How many cars? | Match the count | 有序物品排：3 个 🚗 | 4 点 / 2 点 / 3 点 ✓ | 3 | — | Find the dots that match the cars. | — |
| numbers_05 | 3 | 说名字 | 🚗🚗🚗🚗 / How many cars? | Count the group | 有序物品排：4 个 🚗 | 4 ✓ / 3 / 5 | 4 | — | Count the cars. How many are there? | — |
| numbers_06 | 1 | 看和听 | 🌸🌸🌸🌸🌸 / 🌸 / How many flowers? | How many? | 有序物品排：6 个 🌸（5 上、1 下） | 7 / 5 / 6 ✓ | 6 | — | How many flowers? | Let's count flowers! / 6 |
| numbers_06 | 2 | 概念 | 🌸🌸🌸🌸🌸 / 🌸🌸 / How many flowers? | Count the group | 固定散点表：7 个 🌸，P1–P7 | 7 ✓ / 8 / 6 | 7 | — | Count the scattered flowers. How many are there? | — |
| numbers_06 | 3 | 说名字 | 🌸🌸🌸🌸🌸 / 🌸🌸🌸 / How many flowers? | Count them! | 有序物品排：8 个 🌸（5 上、3 下） | 9 / 8 ✓ / 7 | 8 | — | Count the flowers. How many are there? | — |
| numbers_07 | 1 | 看和听 | 🐟🐟🐟🐟🐟 / 🐟🐟 / How many fish? | How many? | 有序物品排：7 个 🐟（5 上、2 下） | 7 ✓ / 8 / 6 | 7 | — | How many fish? | Let's count fish! / 7 |
| numbers_07 | 2 | 概念 | 🐟🐟🐟🐟🐟 / 🐟🐟🐟🐟 / How many fish? | Count the group | 整齐 3×3 排列：9 个 🐟 | 10 / 9 ✓ / 8 | 9 | 改为规整网格，避免过多散点。 | Count the fish. How many are there? | — |
| numbers_07 | 3 | 说名字 | 🐟🐟🐟🐟🐟 / 🐟 / How many fish? | Count them! | 有序物品排：6 个 🐟（5 上、1 下） | 7 / 5 / 6 ✓ | 6 | — | Count the fish. How many are there? | — |
| numbers_08 | 1 | 看和听 | 🍪🍪🍪🍪🍪 / 🍪🍪🍪 / How many cookies? | How many? | 有序物品排：8 个 🍪（5 上、3 下） | 9 / 8 ✓ / 7 | 8 | — | How many cookies? | Let's count cookies! / 8 |
| numbers_08 | 2 | 概念 | 🍪🍪🍪🍪🍪 / 🍪 / How many cookies? | Count the group | 固定散点表：6 个 🍪，P1–P6 | 7 / 5 / 6 ✓ | 6 | — | Count the scattered cookies. How many are there? | — |
| numbers_08 | 3 | 说名字 | 🍪🍪🍪🍪🍪 / 🍪🍪🍪🍪🍪 / How many cookies? | Count them! | 有序物品排：10 个 🍪（5 上、5 下） | 10 ✓ / 9 / 8 | 10 | — | Count the cookies. How many are there? | — |
| numbers_09 | 1 | 看和听 | 🐞🐞🐞🐞🐞 / 🐞🐞🐞🐞 / How many ladybugs? | How many? | 有序物品排：9 个 🐞（5 上、4 下） | 10 / 8 / 9 ✓ | 9 | — | How many ladybugs? | Let's count ladybugs! / 9 |
| numbers_09 | 2 | 概念 | 🐞🐞🐞🐞🐞 / 🐞🐞🐞🐞🐞 / How many ladybugs? | Count the group | 整齐 2×5 排列：10 个 🐞 | 10 ✓ / 9 / 8 | 10 | 改为规整两行排列。 | Count the ladybugs. How many are there? | — |
| numbers_09 | 3 | 说名字 | 🐞🐞🐞🐞🐞 / 🐞🐞 / How many ladybugs? | Count them! | 有序物品排：7 个 🐞（5 上、2 下） | 6 / 7 ✓ / 8 | 7 | — | Count the ladybugs. How many are there? | — |
| numbers_10 | 1 | 看和听 | 🧸🧸🧸🧸🧸 / 🧸🧸🧸🧸🧸 / How many teddy bears? | How many? | 有序物品排：10 个 🧸（5 上、5 下） | 10 ✓ / 9 / 8 | 10 | — | How many teddy bears? | Let's count teddy bears! / 10 |
| numbers_10 | 2 | 概念 | 🧸🧸🧸🧸🧸 / 🧸🧸🧸 / How many teddy bears? | Count the group | 固定散点表：8 个 🧸，P1–P8 | 9 / 8 ✓ / 7 | 8 | — | Count the scattered teddy bears. How many are there? | — |
| numbers_10 | 3 | 说名字 | 🧸🧸🧸🧸🧸 / 🧸🧸🧸🧸 / How many teddy bears? | Count them! | 有序物品排：9 个 🧸（5 上、4 下） | 10 / 8 / 9 ✓ | 9 | — | Count the teddy bears. How many are there? | — |
| numbers_11 | 1 | 看和听 | 🍎 + 🍎 / 1 + 1 = ? | How many now? | 算式图：1 个 🍋 + 1 个 🍋，结果 ? | 3 / 2 ✓ / 1 | 2 | 用 🍋 替代已在 numbers_02 使用的苹果，避免跨活动复用物品。 | One lemon and one more lemon. How many lemons altogether? | Let's add lemons! / 2 |
| numbers_11 | 2 | 概念 | 🍎🍎 + 🍎 / 2 + 1 = ? | How many now? | 算式图：2 个 🍋 + 1 个 🍋，结果 ? | 4 / 2 / 3 ✓ | 3 | 同一柠檬物品但分组数量不同，运算结果与 Q1 不同。 | Two lemons and one more lemon. How many lemons altogether? | — |
| numbers_11 | 3 | 说名字 | 🍎🍎🍎 + 🍎 / 3 + 1 = ? | How many now? | 算式图：3 个 🍋 + 1 个 🍋，结果 ? | 4 ✓ / 3 / 5 | 4 | 同一柠檬物品但分组数量不同，运算结果与前两题不同。 | Three lemons and one more lemon. How many lemons altogether? | — |
| numbers_12 | 1 | 看和听 | 🐥 + 🐥🐥 / 1 + 2 = ? | How many now? | 算式图：1 只 🐸 + 2 只 🐸，结果 ? | 4 / 2 / 3 ✓ | 3 | 用 🐸 取代已在原题使用的小鸡，并在 Numbers 世界内只用于本活动。 | One frog and two more frogs. How many frogs altogether? | Let's add frogs! / 3 |
| numbers_12 | 2 | 概念 | 🐥🐥 + 🐥🐥 / 2 + 2 = ? | How many now? | 算式图：2 只 🐸 + 2 只 🐸，结果 ? | 4 ✓ / 5 / 3 | 4 | — | Two frogs and two more frogs. How many frogs altogether? | — |
| numbers_12 | 3 | 说名字 | 🐥🐥🐥 + 🐥🐥 / 3 + 2 = ? | How many now? | 算式图：3 只 🐸 + 2 只 🐸，结果 ? | 6 / 5 ✓ / 4 | 5 | — | Three frogs and two more frogs. How many frogs altogether? | — |
| numbers_13 | 1 | 看和听 | 🌟🌟 + 🌟🌟🌟 / 2 + 3 = ? | How many now? | 算式图：2 个 ⚽ + 3 个 ⚽，结果 ? | 5 ✓ / 4 / 6 | 5 | 用 ⚽ 替代已在 numbers_03 使用的星星，避免跨活动复用物品。 | Two balls and three more balls. How many balls altogether? | Let's add balls! / 5 |
| numbers_13 | 2 | 概念 | 🌟🌟🌟🌟 + 🌟 / 4 + 1 = ? | How many now? | 算式图：4 个 ⚽ + 1 个 ⚽，结果 ? | 6 / 5 ✓ / 4 | 5 | 恢复原来的 4+1=5；答案重复，但 cue 与 Q1 不同。 | Four balls and one more ball. How many balls altogether? | — |
| numbers_13 | 3 | 说名字 | 🌟 + 🌟🌟🌟 / 1 + 3 = ? | How many now? | 算式图：1 个 ⚽ + 3 个 ⚽，结果 ? | 5 / 3 / 4 ✓ | 4 | 恢复原来的 1+3=4。 | One ball and three more balls. How many balls altogether? | — |
| numbers_14 | 1 | 看和听 | 🍪🍪🍪 / 3 − 1 = ? | How many left? | 3 辆 🚂 排成一行，划掉 1 辆，结果 ? | 3 / 2 ✓ / 1 | 2 | 用 🚂 替代已在 numbers_08 使用的饼干，避免跨活动复用物品。 | Three trains. One is taken away. How many are left? | Let's take away trains! / 2 |
| numbers_14 | 2 | 概念 | 🍪🍪🍪🍪 / 4 − 1 = ? | How many left? | 4 辆 🚂 排成一行，划掉 1 辆，结果 ? | 4 / 2 / 3 ✓ | 3 | 同一列车 cue 数量不同，结果与 Q1 不同。 | Four trains. One is taken away. How many are left? | — |
| numbers_14 | 3 | 说名字 | 🍪🍪🍪🍪🍪 / 5 − 1 = ? | How many left? | 5 辆 🚂 排成一行，划掉 1 辆，结果 ? | 4 ✓ / 5 / 3 | 4 | 同一列车 cue 数量不同，结果与前两题不同。 | Five trains. One is taken away. How many are left? | — |
| numbers_15 | 1 | 看和听 | 🎈🎈🎈🎈🎈 / 5 − 2 = ? | How many left? | 5 个 🥕 排成一行，划掉 2 个，结果 ? | 4 / 2 / 3 ✓ | 3 | 用 🥕 替代已在 numbers_01 使用的气球，避免跨活动复用物品。 | Five carrots. Two are taken away. How many carrots are left? | Let's take away carrots! / 3 |
| numbers_15 | 2 | 概念 | 🎈🎈🎈🎈 / 4 − 3 = ? | How many left? | 4 个 🥕 排成一行，划掉 3 个，结果 ? | 1 ✓ / 2 / 3 | 1 | 同一胡萝卜 cue 数量和划掉数量均不同，结果与 Q1 不同。 | Four carrots. Three are taken away. How many carrots are left? | — |
| numbers_15 | 3 | 说名字 | 🎈🎈🎈🎈🎈 / 5 − 3 = ? | How many left? | 5 个 🥕 排成一行，划掉 3 个，结果 ? | 3 / 2 ✓ / 1 | 2 | 同一胡萝卜 cue 划掉数量不同，结果与前两题不同。 | Five carrots. Three are taken away. How many carrots are left? | — |
| numbers_16 | 1 | 看和听 | 3 + 3 = ? | 3 + 3 = ? | 十格框：3 个红点 + 3 个蓝点，结果 ? | 6 ✓ / 7 / 5 | 6 | 改用可视化十格框；数字选项和正确答案不变。 | Three dots and three more dots. How many dots altogether? | Let's add dots! / 6 |
| numbers_16 | 2 | 概念 | 4 + 4 = ? | 4 + 4 = ? | 十格框：4 个红点 + 4 个蓝点，结果 ? | 9 / 8 ✓ / 7 | 8 | 改用可视化十格框；数字选项和正确答案不变。 | Four dots and four more dots. How many dots altogether? | — |
| numbers_16 | 3 | 说名字 | 5 + 5 = ? | 5 + 5 = ? | 十格框：5 个红点 + 5 个蓝点，结果 ? | 9 / 8 / 10 ✓ | 10 | 改用可视化十格框；数字选项和正确答案不变。 | Five dots and five more dots. How many dots altogether? | — |
| numbers_17 | 1 | 看和听 | 4 + 3 = ? | 4 + 3 = ? | 十格框：4 个红点 + 3 个蓝点，结果 ? | 8 / 7 ✓ / 6 | 7 | 改用可视化十格框；数字选项和正确答案不变。 | Four dots and three more dots. How many dots altogether? | Let's add dots! / 7 |
| numbers_17 | 2 | 概念 | 6 + 2 = ? | 6 + 2 = ? | 十格框：6 个红点 + 2 个蓝点，结果 ? | 9 / 7 / 8 ✓ | 8 | 改用可视化十格框；数字选项和正确答案不变。 | Six dots and two more dots. How many dots altogether? | — |
| numbers_17 | 3 | 说名字 | 5 + 4 = ? | 5 + 4 = ? | 十格框：5 个红点 + 4 个蓝点，结果 ? | 9 ✓ / 10 / 8 | 9 | 改用可视化十格框；数字选项和正确答案不变。 | Five dots and four more dots. How many dots altogether? | — |
| numbers_18 | 1 | 看和听 | 8 − 3 = ? | 8 − 3 = ? | 十格框：8 个点，其中 3 个划掉，结果 ? | 6 / 4 / 5 ✓ | 5 | 改用可视化十格框；数字选项和正确答案不变。 | Eight dots. Three are crossed out. How many are left? | Let's take away dots! / 5 |
| numbers_18 | 2 | 概念 | 9 − 5 = ? | 9 − 5 = ? | 十格框：9 个点，其中 5 个划掉，结果 ? | 4 ✓ / 5 / 3 | 4 | 改用可视化十格框；数字选项和正确答案不变。 | Nine dots. Five are crossed out. How many are left? | — |
| numbers_18 | 3 | 说名字 | 10 − 4 = ? | 10 − 4 = ? | 十格框：10 个点，其中 4 个划掉，结果 ? | 7 / 6 ✓ / 5 | 6 | 改用可视化十格框；数字选项和正确答案不变。 | Ten dots. Four are crossed out. How many are left? | — |
| numbers_19 | 1 | 看和听 | 7 + ? = 10 | 7 + ? = 10 | 十格框：填 7 格、留 3 格空白，旁边 ? | 3 ✓ / 4 / 2 | 3 | 改用填格与空格表现凑十；数字选项和正确答案不变。 | Seven dots are in the box. How many more make ten? | Let's make ten! / 3 |
| numbers_19 | 2 | 概念 | 6 + ? = 10 | 6 + ? = 10 | 十格框：填 6 格、留 4 格空白，旁边 ? | 5 / 4 ✓ / 3 | 4 | 改用填格与空格表现凑十；数字选项和正确答案不变。 | Six dots are in the box. How many more make ten? | — |
| numbers_19 | 3 | 说名字 | 8 + ? = 10 | 8 + ? = 10 | 十格框：填 8 格、留 2 格空白，旁边 ? | 3 / 1 / 2 ✓ | 2 | 改用填格与空格表现凑十；数字选项和正确答案不变。 | Eight dots are in the box. How many more make ten? | — |
| numbers_20 | 1 | 看和听 | 10 + 3 = ? | 10 + 3 = ? | 两个十格框：第一个填满，第二个填 3 格，结果 ? | 14 / 13 ✓ / 12 | 13 | 改用两个十格框显示十和额外点数；数字选项和正确答案不变。 | Ten dots and three more dots. How many dots altogether? | Let's count teen numbers! / 13 |
| numbers_20 | 2 | 概念 | 10 + 5 = ? | 10 + 5 = ? | 两个十格框：第一个填满，第二个填 5 格，结果 ? | 16 / 14 / 15 ✓ | 15 | 改用两个十格框显示十和额外点数；数字选项和正确答案不变。 | Ten dots and five more dots. How many dots altogether? | — |
| numbers_20 | 3 | 说名字 | 10 + 8 = ? | 10 + 8 = ? | 两个十格框：第一个填满，第二个填 8 格，结果 ? | 18 ✓ / 19 / 17 | 18 | 改用两个十格框显示十和额外点数；数字选项和正确答案不变。 | Ten dots and eight more dots. How many dots altogether? | — |

## Letters — 78 questions (implemented)

The 26 activity ids and their order remain unchanged. Every activity uses Q1
看和听, Q2 找一样的, and Q3 说名字. Q1 teaches the letter name and an example
word; the question itself asks the child to identify the letter from an object
picture. Q2 alternates case direction alphabetically: odd-positioned letters
show a capital cue and lowercase choices; even-positioned letters show a
lowercase cue and capital choices. Q3 shows the letter cue and three pictures.
The X activity is the only exception: Q3 asks for a picture ending in X, and
its `Xx` letter cue does not show the fox.

The `Teach / teachOption` column gives the intro screen text and its existing
letter-plus-picture option. The intro speaks only the teach sentence; Q1
`spokenText` is a separate question. Hints can use `Say the word slowly.` for
Q1, `Look at each letter.` for Q2, and `Say each picture.` for Q3 (4, 4, and
3 words). Every prompt below has at most 3 words, and every teach sentence has
at most 8 words. Letters are spoken as letter names, never phonetic syllables.
The Q3 option words, initials, and initial sounds are also listed separately
below so the distractors can be reviewed independently.

| Activity | Q | PlayType | Current prompt | New short prompt | Cue | Options (correct marked) | Original correct answer | Answer change reason | spokenText | Teach / teachOption |
|---|---:|---|---|---|---|---|---|---|---|---|
| letters_a | 1 | 看和听 | Tap the letter that matches 🍎 | Which letter? | 🍎 | A 🍎 ✓ / E 🐘 / L 🦁 | A | 改为物品 cue 和简短识字提示。 | Which letter is for apple? | A is for apple. / A + 🍎 |
| letters_a | 2 | 找一样的 | Find the letter A | Same letter? | 大写 A | t / a ✓ / w | A | 改为大写 cue 配小写选项，排除圆形相似字母。 | Find the small letter that matches this capital A. | — |
| letters_a | 3 | 说名字 | Which picture starts with the letter A? | Starts with A? | Aa | Bus 🚌 / Cup 🥤 / Ant 🐜 ✓ | Apple | 用 bus 替换 book，避免与 notebook 图义相近。 | Which picture starts with the letter A? | — |
| letters_b | 1 | 看和听 | Tap the letter that matches ⚽ | Which letter? | ⚽ | F 🐟 / B ⚽ ✓ / M 🌙 | B | 改为物品 cue 和简短识字提示。 | Which letter is for ball? | B is for ball. / B + ⚽ |
| letters_b | 2 | 找一样的 | Find the letter B | Same letter? | 小写 b | C / K / B ✓ | B | 改为小写 cue 配大写选项。 | Find the capital letter that matches this small b. | — |
| letters_b | 3 | 说名字 | Which picture starts with the letter B? | Starts with B? | Bb | Banana 🍌 ✓ / Duck 🦆 / Flower 🌼 | Ball | 使用不与本世界 Q1 cue 重复的 B 词图片。 | Which picture starts with the letter B? | — |
| letters_c | 1 | 看和听 | Tap the letter that matches 🐱 | Which letter? | 🐱 | G 🍇 / N 👃 / C 🐱 ✓ | C | 改为物品 cue 和简短识字提示。 | Which letter is for cat? | C is for cat. / C + 🐱 |
| letters_c | 2 | 找一样的 | Find the letter C | Same letter? | 大写 C | c ✓ / f / x | C | 改为大写 cue 配小写选项。 | Find the small letter that matches this capital C. | — |
| letters_c | 3 | 说名字 | Which picture starts with the letter C? | Starts with C? | Cc | Train 🚆 / Crab 🦀 ✓ / Map 🗺️ | Cat | 使用不与本世界 Q1 cue 重复的 C 词图片。 | Which picture starts with the letter C? | — |
| letters_d | 1 | 看和听 | Tap the letter that matches 🐶 | Which letter? | 🐶 | D 🐶 ✓ / H 🎩 / O 🍊 | D | 改为物品 cue 和简短识字提示。 | Which letter is for dog? | D is for dog. / D + 🐶 |
| letters_d | 2 | 找一样的 | Find the letter D | Same letter? | 小写 d | F / D ✓ / G | D | 改为小写 cue 配大写选项。 | Find the capital letter that matches this small d. | — |
| letters_d | 3 | 说名字 | Which picture starts with the letter D? | Starts with D? | Dd | Gift 🎁 / Candle 🕯️ / Drum 🥁 ✓ | Dog | 使用不与本世界 Q1 cue 重复的 D 词图片。 | Which picture starts with the letter D? | — |
| letters_e | 1 | 看和听 | Tap the letter that matches 🐘 | Which letter? | 🐘 | I 🍦 / E 🐘 ✓ / P 🍕 | E | 改为物品 cue 和简短识字提示。 | Which letter is for elephant? | E is for elephant. / E + 🐘 |
| letters_e | 2 | 找一样的 | Find the letter E | Same letter? | 大写 E | j / k / e ✓ | E | 改为大写 cue 配小写选项。 | Find the small letter that matches this capital E. | — |
| letters_e | 3 | 说名字 | Which picture starts with the letter E? | Starts with E? | Ee | Egg 🥚 ✓ / Rabbit 🐇 / Tiger 🐅 | Elephant | 使用不与本世界 Q1 cue 重复的 E 词图片。 | Which picture starts with the letter E? | — |
| letters_f | 1 | 看和听 | Tap the letter that matches 🐟 | Which letter? | 🐟 | J 👖 / Q 👸 / F 🐟 ✓ | F | 改为物品 cue 和简短识字提示。 | Which letter is for fish? | F is for fish. / F + 🐟 |
| letters_f | 2 | 找一样的 | Find the letter F | Same letter? | 小写 f | F ✓ / O / M | F | 改为小写 cue 配大写选项，并用不同形状的干扰字母。 | Find the capital letter that matches this small f. | — |
| letters_f | 3 | 说名字 | Which picture starts with the letter F? | Starts with F? | Ff | Crown 👑 / Frog 🐸 ✓ / Bear 🐻 | Fish | 使用不与本世界 Q1 cue 重复的 F 词图片。 | Which picture starts with the letter F? | — |
| letters_g | 1 | 看和听 | Tap the letter that matches 🍇 | Which letter? | 🍇 | G 🍇 ✓ / K 🔑 / R 🌈 | G | 改为物品 cue 和简短识字提示。 | Which letter is for grapes? | G is for grapes. / G + 🍇 |
| letters_g | 2 | 找一样的 | Find the letter G | Same letter? | 大写 G | t / g ✓ / k | G | 改为大写 cue 配小写选项，排除圆形相似字母。 | Find the small letter that matches this capital G. | — |
| letters_g | 3 | 说名字 | Which picture starts with the letter G? | Starts with G? | Gg | Shoe 👟 / Clock 🕒 / Goat 🐐 ✓ | Grapes | 将 shoes 改为与单个鞋子图片一致的 shoe。 | Which picture starts with the letter G? | — |
| letters_h | 1 | 看和听 | Tap the letter that matches 🎩 | Which letter? | 🎩 | L 🦁 / H 🎩 ✓ / S ☀️ | H | 改为物品 cue 和简短识字提示。 | Which letter is for hat? | H is for hat. / H + 🎩 |
| letters_h | 2 | 找一样的 | Find the letter H | Same letter? | 小写 h | L / T / H ✓ | H | 改为指定的大写选项，干扰字母不与 h 同形组。 | Find the capital letter that matches this small h. | — |
| letters_h | 3 | 说名字 | Which picture starts with the letter H? | Starts with H? | Hh | House 🏠 ✓ / Mushroom 🍄 / Kite 🪁 | Hat | 使用不与本世界 Q1 cue 重复的 H 词图片。 | Which picture starts with the letter H? | — |
| letters_i | 1 | 看和听 | Tap the letter that matches 🍦 | Which letter? | 🍦 | M 🌙 / T 🌳 / I 🍦 ✓ | I | 改为物品 cue 和简短识字提示。 | Which letter is for ice cream? | I is for ice cream. / I + 🍦 |
| letters_i | 2 | 找一样的 | Find the letter I | Same letter? | 大写 I | i ✓ / c / x | I | 改为大写 cue 配小写选项。 | Find the small letter that matches this capital I. | — |
| letters_i | 3 | 说名字 | Which picture starts with the letter I? | Starts with I? | Ii | Boat ⛵ / Ice 🧊 ✓ / Cake 🍰 | Ice cream | 使用 ice cube 表示 ice，避免复用冰淇淋 cue。 | Which picture starts with the letter I? | — |
| letters_j | 1 | 看和听 | Tap the letter that matches 👖 | Which letter? | 👖 | J 👖 ✓ / N 👃 / U ☂️ | J | 改为物品 cue 和简短识字提示。 | Which letter is for jeans? | J is for jeans. / J + 👖 |
| letters_j | 2 | 找一样的 | Find the small letter j | Same letter? | 小写 j | G / J ✓ / X | J | 改为小写 cue 配大写选项。 | Find the capital letter that matches this small j. | — |
| letters_j | 3 | 说名字 | Which picture starts with the letter J? | Starts with J? | Jj | Donut 🍩 / Lemon 🍋 / Juice 🧃 ✓ | Jeans | 用 lemon 替换与 juice 首音易混淆的 chicken。 | Which picture starts with the letter J? | — |
| letters_k | 1 | 看和听 | Tap the letter that matches 🔑 | Which letter? | 🔑 | O 🍊 / K 🔑 ✓ / V 🎻 | K | 改为物品 cue 和简短识字提示。 | Which letter is for key? | K is for key. / K + 🔑 |
| letters_k | 2 | 找一样的 | Find the small letter k | Same letter? | 大写 K | t / m / k ✓ | K | 改为大写 cue 配小写选项。 | Find the small letter that matches this capital K. | — |
| letters_k | 3 | 说名字 | Which picture starts with the letter K? | Starts with K? | Kk | Koala 🐨 ✓ / Tea 🍵 / Broom 🧹 | Key | 用不同首音的 tea 替换 soup；mop 改为 broom。 | Which picture starts with the letter K? | — |
| letters_l | 1 | 看和听 | Tap the letter that matches 🦁 | Which letter? | 🦁 | P 🍕 / W 🐳 / L 🦁 ✓ | L | 改为物品 cue 和简短识字提示。 | Which letter is for lion? | L is for lion. / L + 🦁 |
| letters_l | 2 | 找一样的 | Find the small letter l | Same letter? | 小写 l | L ✓ / C / X | L | 改为小写 cue 配大写选项。 | Find the capital letter that matches this small l. | — |
| letters_l | 3 | 说名字 | Which picture starts with the letter L? | Starts with L? | Ll | Bicycle 🚲 / Leaf 🍃 ✓ / Panda 🐼 | Lion | 使用不与本世界 Q1 cue 重复的 L 词图片。 | Which picture starts with the letter L? | — |
| letters_m | 1 | 看和听 | Tap the letter that matches 🌙 | Which letter? | 🌙 | M 🌙 ✓ / Q 👸 / Y 🧶 | M | 改为物品 cue 和简短识字提示。 | Which letter is for moon? | M is for moon. / M + 🌙 |
| letters_m | 2 | 找一样的 | Find the small letter m | Same letter? | 大写 M | t / m ✓ / k | M | 改为大写 cue 配小写选项，避开拱形相似字母。 | Find the small letter that matches this capital M. | — |
| letters_m | 3 | 说名字 | Which picture starts with the letter M? | Starts with M? | Mm | Carrot 🥕 / Globe 🌍 / Mouse 🐭 ✓ | Moon | 使用不与本世界 Q1 cue 重复的 M 词图片。 | Which picture starts with the letter M? | — |
| letters_n | 1 | 看和听 | Tap the letter that matches 👃 | Which letter? | 👃 | R 🌈 / N 👃 ✓ / Y 🧶 | N | 改为物品 cue 和简短识字提示。 | Which letter is for nose? | N is for nose. / N + 👃 |
| letters_n | 2 | 找一样的 | Find the small letter n | Same letter? | 小写 n | T / K / N ✓ | N | 改为小写 cue 配大写选项。 | Find the capital letter that matches this small n. | — |
| letters_n | 3 | 说名字 | Which picture starts with the letter N? | Starts with N? | Nn | Notebook 📓 ✓ / Pear 🍐 / Cow 🐄 | Nose | 使用 notebook 图片和不同首字母的辅音干扰项。 | Which picture starts with the letter N? | — |
| letters_o | 1 | 看和听 | Tap the letter that matches 🍊 | Which letter? | 🍊 | S ☀️ / Z 🦓 / O 🍊 ✓ | O | 改为物品 cue 和简短识字提示。 | Which letter is for orange? | O is for orange. / O + 🍊 |
| letters_o | 2 | 找一样的 | Find the small letter o | Same letter? | 大写 O | o ✓ / t / k | O | 改为大写 cue 配小写选项，排除圆形相似字母。 | Find the small letter that matches this capital O. | — |
| letters_o | 3 | 说名字 | Which picture starts with the letter O? | Starts with O? | Oo | Hamburger 🍔 / Octopus 🐙 ✓ / Door 🚪 | Orange | 使用不与本世界 Q1 cue 重复的 O 词图片。 | Which picture starts with the letter O? | — |
| letters_p | 1 | 看和听 | Tap the letter that matches 🍕 | Which letter? | 🍕 | P 🍕 ✓ / T 🌳 / A 🍎 | P | 改为物品 cue 和简短识字提示。 | Which letter is for pizza? | P is for pizza. / P + 🍕 |
| letters_p | 2 | 找一样的 | Find the small letter p | Same letter? | 小写 p | C / P ✓ / K | P | 改为小写 cue 配大写选项。 | Find the capital letter that matches this small p. | — |
| letters_p | 3 | 说名字 | Which picture starts with the letter P? | Starts with P? | Pp | Baseball ⚾ / Dragon 🐉 / Pig 🐷 ✓ | Pizza | 使用不与本世界 Q1 cue 重复的 P 词图片。 | Which picture starts with the letter P? | — |
| letters_q | 1 | 看和听 | Tap the letter that matches 👸 | Which letter? | 👸 | U ☂️ / Q 👸 ✓ / B ⚽ | Q | 恢复 queen 图片及 teach，与 Q3 的 question 图片区分。 | Which letter is for queen? | Q is for queen. / Q + 👸 |
| letters_q | 2 | 找一样的 | Find the small letter q | Same letter? | 大写 Q | t / w / q ✓ | Q | 改为大写 cue 配小写选项，排除圆形及竖线相似字母。 | Find the small letter that matches this capital Q. | — |
| letters_q | 3 | 说名字 | Which picture starts with the letter Q? | Starts with Q? | Qq | Question ❓ ✓ / Bell 🔔 / Peach 🍑 | Queen | 正确答案改为 question；替换两张 Unicode 13 图片。 | Which picture starts with the letter Q? | — |
| letters_r | 1 | 看和听 | Tap the letter that matches 🌈 | Which letter? | 🌈 | V 🎻 / C 🐱 / R 🌈 ✓ | R | 改为物品 cue 和简短识字提示。 | Which letter is for rainbow? | R is for rainbow. / R + 🌈 |
| letters_r | 2 | 找一样的 | Find the small letter r | Same letter? | 小写 r | R ✓ / T / K | R | 改为小写 cue 配大写选项。 | Find the capital letter that matches this small r. | — |
| letters_r | 3 | 说名字 | Which picture starts with the letter R? | Starts with R? | Rr | Bread 🍞 / Rocket 🚀 ✓ / Snake 🐍 | Rainbow | 使用不与本世界 Q1 cue 重复的 R 词图片。 | Which picture starts with the letter R? | — |
| letters_s | 1 | 看和听 | Tap the letter that matches ☀️ | Which letter? | ☀️ | S ☀️ ✓ / W 🐳 / D 🐶 | S | 改为物品 cue 和简短识字提示。 | Which letter is for sun? | S is for sun. / S + ☀️ |
| letters_s | 2 | 找一样的 | Tap the small letter for S | Same letter? | 大写 S | a / s ✓ / k | S | 改为大写 cue 配小写选项。 | Find the small letter that matches this capital S. | — |
| letters_s | 3 | 说名字 | Which picture starts with the letter S? | Starts with S? | Ss | Bed 🛏️ / Milk 🥛 / Sock 🧦 ✓ | Sun | 使用不与本世界 Q1 cue 重复的 S 词图片。 | Which picture starts with the letter S? | — |
| letters_t | 1 | 看和听 | Tap the letter that matches 🌳 | Which letter? | 🌳 | Y 🧶 / T 🌳 ✓ / E 🐘 | T | 改为物品 cue 和简短识字提示。 | Which letter is for tree? | T is for tree. / T + 🌳 |
| letters_t | 2 | 找一样的 | Tap the small letter for T | Same letter? | 小写 t | C / K / T ✓ | T | 改为小写 cue 配大写选项。 | Find the capital letter that matches this small t. | — |
| letters_t | 3 | 说名字 | Which picture starts with the letter T? | Starts with T? | Tt | Turtle 🐢 ✓ / Sheep 🐑 / Piano 🎹 | Tree | 使用不与本世界 Q1 cue 重复的 T 词图片。 | Which picture starts with the letter T? | — |
| letters_u | 1 | 看和听 | Tap the letter that matches ☂️ | Which letter? | ☂️ | Y 🧶 / F 🐟 / U ☂️ ✓ | U | 改为物品 cue 和简短识字提示。 | Which letter is for umbrella? | U is for umbrella. / U + ☂️ |
| letters_u | 2 | 找一样的 | Tap the small letter for U | Same letter? | 大写 U | u ✓ / t / k | U | 改为大写 cue 配小写选项。 | Find the small letter that matches this capital U. | — |
| letters_u | 3 | 说名字 | Which picture starts with the letter U? | Starts with U? | Uu | Scissors ✂️ / Unicorn 🦄 ✓ / Bulb 💡 | Umbrella | 将 lamp 改为与灯泡图片一致的 bulb。 | Which picture starts with the letter U? | — |
| letters_v | 1 | 看和听 | Tap the letter that matches 🎻 | Which letter? | 🎻 | V 🎻 ✓ / Z 🦓 / G 🍇 | V | 改为物品 cue 和简短识字提示。 | Which letter is for violin? | V is for violin. / V + 🎻 |
| letters_v | 2 | 找一样的 | Tap the small letter for V | Same letter? | 小写 v | C / V ✓ / T | V | 改为小写 cue 配大写选项。 | Find the capital letter that matches this small v. | — |
| letters_v | 3 | 说名字 | Which picture starts with the letter V? | Starts with V? | Vv | Robot 🤖 / Medal 🏅 / Van 🚐 ✓ | Violin | 使用不与本世界 Q1 cue 重复的 V 词图片。 | Which picture starts with the letter V? | — |
| letters_w | 1 | 看和听 | Tap the letter that matches 🐳 | Which letter? | 🐳 | A 🍎 / W 🐳 ✓ / H 🎩 | W | 改为物品 cue 和简短识字提示。 | Which letter is for whale? | W is for whale. / W + 🐳 |
| letters_w | 2 | 找一样的 | Tap the small letter for W | Same letter? | 大写 W | c / t / w ✓ | W | 改为大写 cue 配小写选项。 | Find the small letter that matches this capital W. | — |
| letters_w | 3 | 说名字 | Which picture starts with the letter W? | Starts with W? | Ww | Watermelon 🍉 ✓ / Shell 🐚 / Glove 🧤 | Whale | 使用不与本世界 Q1 cue 重复的 W 词图片。 | Which picture starts with the letter W? | — |
| letters_x | 1 | 看和听 | Which letter makes the sound at the end of fox? | Which letter? | 📦 | F 🐟 / O 🍊 / X 📦 ✓ | X | 将 X 的物品 cue 改为 box；Q1 只讲字母名，不读拟音词。 | Which letter ends the word box? | X is at the end of box. / X + 📦 |
| letters_x | 2 | 找一样的 | Tap the small letter for X | Same letter? | 小写 x | X ✓ / C / T | X | 改为小写 cue 配大写选项。 | Find the capital letter that matches this small x. | — |
| letters_x | 3 | 说名字 | Which picture ends with the letter X? | Ends with X? | Xx（只显示字母，不放狐狸） | Cheese 🧀 / Fox 🦊 ✓ / Monkey 🐒 | Fox | 正确图片以 X 结尾；cue 不含答案图片。 | Which picture ends with the letter X? | — |
| letters_y | 1 | 看和听 | Tap the letter that matches 🧶 | Which letter? | 🧶 | Y 🧶 ✓ / C 🐱 / J 👖 | Y | 改为物品 cue 和简短识字提示。 | Which letter is for yarn? | Y is for yarn. / Y + 🧶 |
| letters_y | 2 | 找一样的 | Tap the small letter for Y | Same letter? | 大写 Y | c / y ✓ / t | Y | 改为大写 cue 配小写选项。 | Find the small letter that matches this capital Y. | — |
| letters_y | 3 | 说名字 | Which picture starts with the letter Y? | Starts with Y? | Yy | Bottle 🍼 / Eagle 🦅 / Yo-yo 🪀 ✓ | Yarn | 使用不与本世界 Q1 cue 重复的 Y 词图片。 | Which picture starts with the letter Y? | — |
| letters_z | 1 | 看和听 | Tap the letter that matches 🦓 | Which letter? | 🦓 | D 🐶 / Z 🦓 ✓ / K 🔑 | Z | 改为物品 cue 和简短识字提示。 | Which letter is for zebra? | Z is for zebra. / Z + 🦓 |
| letters_z | 2 | 找一样的 | Tap the small letter for Z | Same letter? | 小写 z | C / T / Z ✓ | Z | 改为小写 cue 配大写选项。 | Find the capital letter that matches this small z. | — |
| letters_z | 3 | 说名字 | Which picture starts with the letter Z? | Starts with Z? | Zz | Zero 0️⃣ ✓ / Bee 🐝 / Pencil ✏️ | Zebra | 用零的符号表示 zero，且不复用 Zebra cue。 | Which picture starts with the letter Z? | — |

### Letters Q3 distractor check

Each row lists all three Q3 option words, their first letters, and initial
sounds. X is the sole ending-sound item; its answer ends in X, while both
distractors have different first letters and sounds. Each Q3 picture is unique
within Letters and distinct from every Q1 cue picture.

| Activity | Correct word / initial / sound | Distractor 1 / initial / sound | Distractor 2 / initial / sound |
|---|---|---|---|
| letters_a | Ant / A / æ | Bus / B / b | Cup / C / k |
| letters_b | Banana / B / b | Duck / D / d | Flower / F / f |
| letters_c | Crab / C / k | Train / T / t | Map / M / m |
| letters_d | Drum / D / d | Gift / G / g | Candle / C / k |
| letters_e | Egg / E / ɛ | Rabbit / R / r | Tiger / T / t |
| letters_f | Frog / F / f | Crown / C / k | Bear / B / b |
| letters_g | Goat / G / g | Shoe / S / ʃ | Clock / C / k |
| letters_h | House / H / h | Mushroom / M / m | Kite / K / k |
| letters_i | Ice / I / aɪ | Boat / B / b | Cake / C / k |
| letters_j | Juice / J / dʒ | Donut / D / d | Lemon / L / l |
| letters_k | Koala / K / k | Tea / T / t | Broom / B / b |
| letters_l | Leaf / L / l | Bicycle / B / b | Panda / P / p |
| letters_m | Mouse / M / m | Carrot / C / k | Globe / G / g |
| letters_n | Notebook / N / n | Pear / P / p | Cow / C / k |
| letters_o | Octopus / O / ɑ | Hamburger / H / h | Door / D / d |
| letters_p | Pig / P / p | Baseball / B / b | Dragon / D / d |
| letters_q | Question / Q / kw | Bell / B / b | Peach / P / p |
| letters_r | Rocket / R / r | Bread / B / b | Snake / S / s |
| letters_s | Sock / S / s | Bed / B / b | Milk / M / m |
| letters_t | Turtle / T / t | Sheep / S / ʃ | Piano / P / p |
| letters_u | Unicorn / U / j | Scissors / S / s | Bulb / B / b |
| letters_v | Van / V / v | Robot / R / r | Medal / M / m |
| letters_w | Watermelon / W / w | Shell / S / ʃ | Glove / G / g |
| letters_x | Fox / X (ending) / ks | Cheese / C / tʃ | Monkey / M / m |
| letters_y | Yo-yo / Y / j | Bottle / B / b | Eagle / E / i |
| letters_z | Zero / Z / z | Bee / B / b | Pencil / P / p |

### Letters implementation notes

- `LetterCue(String text)` uses `identityKey` `letter:$text`. Render the
  large letter(s) in a `FittedBox` filling the question card. Keep `Aa` and
  single-letter cues on one line. Q1 uses the existing `EmojiCue`.
- Q1 answer tiles and `teachOption` retain the existing `letterPicture`
  visual. Q2 uses case-opposite text letter tiles. Q3 uses three picture
  options; no object is reused among the 26 Q1 cues or 78 Q3 options.
- For Q2 the case direction alternates A capital → lowercase, B lowercase →
  capital, continuing through Z. Distractors never include a visually
  confusable pair such as b/d/p/q, m/n, u/v, or i/j in one question.
- Q3 distractors have distinct starting letters and sounds from the target
  and from one another. The A/E/I/O/U distractors are all consonant-initial.
- Keep the activity ids, section order, minAge, three choices, and correct
  answer positions unchanged when implementing the approved proposal.

### Numbers notes

- In every activity Q1, Q2, and Q3 use three different play types. Counting
  activities vary the pictured quantity and numeric/dot-card correct answer;
  addition and subtraction vary the operands, cue, and answer. numbers_13's
  original sums (2+3, 4+1, 1+3) are preserved; its answer 5 repeats because
  Q1 and Q2 have different cues.
- numbers_01–05 Q2 is matching the pictured item count to dot-card choices.
  numbers_06, numbers_08, and numbers_10 Q2 use the fixed scattered position
  map above; numbers_07 is a 3-by-3 grid and numbers_09 is two orderly rows of
  five. Q1 and Q3 use orderly rows.
- numbers_11–13 use unique item objects (lemon, frog, ball); numbers_14–15 use
  unique item objects (train, carrot). Each arithmetic picture and answer is
  different across the activity's three questions.
- numbers_16–18 use ten-frames for addition or take-away. numbers_19 shows
  the known dots in red and the missing part of ten as `?` dots, while
  numbers_20 uses a full frame plus a frame of `?` dots to show teen numbers.
- Every Q1 has a short teach sentence and its existing `teachOption`; the
  first question's spoken instruction is separate from the intro speech.
