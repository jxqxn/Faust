# GameScene hand-card layout

This is the source geometry contract for the persistent hand. It is not a
clone-side 1280×720 measurement.

## Authored evidence

| source object | authored data | clone mapping |
| --- | --- | --- |
| `GameScene/MainUI/Hand Mask` | stretch-x, `sizeDelta.y=470` | `CardRail`: full-width bottom band, height 470 |
| `GameScene/MainUI/Hand` | anchors `(0,0)-(1,0)`, anchored `(-63.967773,4)`, `sizeDelta=(-1116.736,430)`, pivot `(0.52,0)` | resolved at 3840×2160 to `(516.7349,1726)` / `2723.264×430` |
| `HandCardsController` | `minFullCount=10`, `minVisibleWidth=20`, `reserveWidth=0`, `Space=10`, `Range=0` | source-width row; when it overflows, preserve 20 pixels of each card |
| `CardNew.prefab` | root `194×422`; Outline `256×525` at `(0,22)` | normal card root size |
| `SudanCard.prefab` | root `185×330` | Sudan-card root size |

The resolved Hand rectangle uses Unity's stretch-axis equations:

`left = anchoredX - pivotX × sizeDeltaX = 516.7349`

`right inset = -(anchoredX + (1 - pivotX) × sizeDeltaX) = 600.0013`

In Godot's top-left coordinates its top is `2160 - (4 + 430) = 1726`.

## Behaviour evidence

`CardController.Init` / `InitInBag` instantiate the presentation returned by
`GameApplication.GetCardShowPrefab`, then `HandCardsController.Update` reads
each child `RectTransform.sizeDelta × localScale` before placing it. The hand
therefore cannot be represented faithfully by one clone-wide card size or a
global 3× mockup scale.

Sources: `engine_spec/decompiled/CardController.c` (`Init`, `InitInBag`),
`engine_spec/decompiled/HandCardsController.c` (`Update`), `dump.cs`
`CardController` / `HandCardsController`, and the original scene/prefabs
listed above.
