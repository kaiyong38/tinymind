# TinyMind question bank redesign

This is a staged proposal. Shapes (36 questions) and Colors (36 questions) are
specified and implemented; Numbers and Letters rows are added next, in that
order, after the preceding world's proposal is confirmed.

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
| shapes_01 | 3 | 生活中的物品 | Which one is round like a circle? | Which looks round? | 大圆形 | Gift（方）/ Tent（三角）/ Ball ✓（圆） | Ball | — | Which object is round like this circle? |
| shapes_02 | 1 | 看和听 | Tap the square | Square | 橙色正方形 | triangle / Square ✓ / circle | square | — | Tap the square. |
| shapes_02 | 2 | 找一样的 | Tap the square | Match shape | 深灰正方形剪影 | circle / triangle / square ✓ | square | — | Find the shape that matches this square. |
| shapes_02 | 3 | 生活中的物品 | Which one looks like a square? | Which looks square? | 大正方形 | Gift ✓（方）/ Cookie（圆）/ Pizza slice（三角） | Gift | — | Which object looks like this square? |
| shapes_03 | 1 | 看和听 | Tap the triangle | Triangle | 绿色三角形 | star / circle / Triangle ✓ | triangle | — | Tap the triangle. |
| shapes_03 | 2 | 找一样的 | Tap the triangle | Match shape | 深灰三角形剪影 | triangle ✓ / square / circle | triangle | — | Find the shape that matches this triangle. |
| shapes_03 | 3 | 生活中的物品 | Which one looks like a triangle? | Which looks pointy? | 大三角形 | Cookie（圆）/ Pizza slice ✓（三角）/ Gift（方） | Pizza slice | — | Which object is pointy like this triangle? |
| shapes_04 | 1 | 看和听 | Tap the star | Star | 黄色星形 | Star ✓ / circle / square | star | — | Tap the star. |
| shapes_04 | 2 | 找一样的 | Which shape twinkles in the night sky? | Match shape | 深灰星形剪影 | triangle / star ✓ / circle | star | — | Find the shape that matches this star. |
| shapes_04 | 3 | 生活中的物品 | Which one is a star? | Twinkles? | 闪光 ✨ | Rainbow / Cloud / Star ✓ | Star | — | Which one twinkles in the night sky? |
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
| shapes_12 | 2 | 概念 | Which shape rolls the best? | Rolls best? | 斜坡加滚动箭头，无形状图案 | circle ✓ / square / triangle | circle | — | Which shape rolls smoothly down a slope? |
| shapes_12 | 3 | 说名字 | Which shape has 3 sides? | 3 sides? | 大数字 3；选项形状的每条边用不同颜色（圆形只有一条灰色轮廓） | square / triangle ✓ / circle | triangle | — | Which shape has three sides? |

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

### Changes after device testing (October 2026)

- The intro screen of an activity now reads the text shown on it. The first question's `spokenText` is the instruction only ("Tap the circle."), so the same sentence is not read twice.
- The read-aloud button in the question card was removed; the header button is the only one, and tapping the card still repeats the question.
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
