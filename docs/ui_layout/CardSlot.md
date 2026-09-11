# UI layout manifest: Resources/prefab/CardSlot.prefab

Corpus truth table (RectTransform, authored values). Regenerate with `tools/export_ui_layout.gd`.

## Canvases

| name | scaler |
| --- | --- |
| GamepadPrompt | constant-pixel-size |

## Nodes

| path | anchors | pos | size | pivot | scale | rotZ | extras |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CardSlot | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (272.00, 496.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardSlot/BG | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (272.00, 496.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/rite/template/slot_bg/nomal_slot_bg.asset |
| CardSlot/Prompt | (0.50, 0.50)–(0.50, 0.50) | (6.00, -19.00) | (272.00, 496.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Sprite/outline_0.asset |
| CardSlot/OutlineNew | (0.50, 0.50)–(0.50, 0.50) | (0.00, -19.00) | (197.00, 423.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Sprite/outline_new.asset |
| CardSlot/Types | (0.50, 0.50)–(0.50, 0.50) | (0.00, -25.00) | (100.00, 300.00) | (0.50, 0.50) | (1.70, 1.70) | 0.0 | layout(align=4 spacing=0.0 pad=[0, 0, 0, 0] cc=0/0 fe=0/0 rev=0) |
| CardSlot/Text | (0.50, 0.00)–(0.50, 0.00) | (0.00, 0.00) | (160.00, 30.00) | (0.50, 1.00) | (1.00, 1.00) | 0.0 | text="New Text" fs=20 |
| CardSlot/Container | (0.50, 0.50)–(0.50, 0.50) | (1.60, -19.60) | (100.00, 100.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardSlot/Highlight | (0.50, 0.50)–(0.50, 0.50) | (0.00, -19.00) | (256.00, 512.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Sprite/card_outline.asset |
| CardSlot/Outline | (0.50, 0.50)–(0.50, 0.50) | (0.00, -19.00) | (197.00, 423.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Sprite/outline_new.asset |
| CardSlot/Adsorb | (0.50, 0.50)–(0.50, 0.50) | (0.00, -85.00) | (250.00, 38.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Sprite/slot_locked.asset |
| CardSlot/GamepadPromptHolder | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (100.00, 100.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardSlot/GamepadPromptHolder/GamepadPrompt | (1.00, 0.00)–(1.00, 1.00) | (34.00, -30.00) | (100.00, 336.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | layout(align=0 spacing=30.0 pad=[0, 0, 0, 0] cc=0/0 fe=0/0 rev=0) |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ChooseCard | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (54.00, 56.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ChooseCard/Text (TMP) | (0.00, 0.00)–(1.00, 1.00) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | text="C" fs=60 |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.50, 1.50) | 0.0 |  |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Text | (0.00, 0.50)–(0.00, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | fitter(h=2 v=2) |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Sprites | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | 0.0 | fitter(h=2 v=2) |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Sprites/First | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/A.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Sprites/First/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Sprites/First/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Sprites/Spacer | (0.00, 1.00)–(0.00, 1.00) | (94.50, -41.00) | (5.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Sprites/Plus | (0.00, 1.00)–(0.00, 1.00) | (107.00, -41.00) | (69.00, 76.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/+.png_0.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Sprites/Second | (0.00, 1.00)–(0.00, 1.00) | (186.00, -41.00) | (82.00, 82.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/B.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Sprites/Second/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Sprites/Second/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ChooseCard/Image | (0.50, 0.50)–(0.50, 0.50) | (88.60, 32.00) | (48.00, 52.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/op_hand.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/RemoveCard | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (54.00, 56.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardSlot/GamepadPromptHolder/GamepadPrompt/RemoveCard/Text (TMP) | (0.00, 0.00)–(1.00, 1.00) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | text="R" fs=60 |
| CardSlot/GamepadPromptHolder/GamepadPrompt/RemoveCard/InputDisplay | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.50, 1.50) | 0.0 |  |
| CardSlot/GamepadPromptHolder/GamepadPrompt/RemoveCard/InputDisplay/Text | (0.00, 0.50)–(0.00, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | fitter(h=2 v=2) |
| CardSlot/GamepadPromptHolder/GamepadPrompt/RemoveCard/InputDisplay/Sprites | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | 0.0 | fitter(h=2 v=2) |
| CardSlot/GamepadPromptHolder/GamepadPrompt/RemoveCard/InputDisplay/Sprites/First | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/A.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/RemoveCard/InputDisplay/Sprites/First/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/RemoveCard/InputDisplay/Sprites/First/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/RemoveCard/InputDisplay/Sprites/Spacer | (0.00, 1.00)–(0.00, 1.00) | (94.50, -41.00) | (5.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardSlot/GamepadPromptHolder/GamepadPrompt/RemoveCard/InputDisplay/Sprites/Plus | (0.00, 1.00)–(0.00, 1.00) | (107.00, -41.00) | (69.00, 76.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/+.png_0.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/RemoveCard/InputDisplay/Sprites/Second | (0.00, 1.00)–(0.00, 1.00) | (186.00, -41.00) | (82.00, 82.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/B.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/RemoveCard/InputDisplay/Sprites/Second/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/RemoveCard/InputDisplay/Sprites/Second/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/RemoveCard/Image | (0.50, 0.50)–(0.50, 0.50) | (90.90, 26.60) | (48.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/op_remove.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowCardInfo | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (54.00, 56.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/Text (TMP) | (0.00, 0.00)–(1.00, 1.00) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | text="S" fs=60 |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.50, 1.50) | 0.0 |  |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Text | (0.00, 0.50)–(0.00, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | fitter(h=2 v=2) |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Sprites | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | 0.0 | fitter(h=2 v=2) |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Sprites/First | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/A.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Sprites/First/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Sprites/First/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Sprites/Spacer | (0.00, 1.00)–(0.00, 1.00) | (94.50, -41.00) | (5.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Sprites/Plus | (0.00, 1.00)–(0.00, 1.00) | (107.00, -41.00) | (69.00, 76.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/+.png_0.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Sprites/Second | (0.00, 1.00)–(0.00, 1.00) | (186.00, -41.00) | (82.00, 82.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/B.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Sprites/Second/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Sprites/Second/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/Image | (0.50, 0.50)–(0.50, 0.50) | (93.10, 26.40) | (48.00, 40.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/op_info.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowSlotTips | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (54.00, 56.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowSlotTips/Text (TMP) | (0.00, 0.00)–(1.00, 1.00) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | text="S" fs=60 |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowSlotTips/InputDisplay | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.50, 1.50) | 0.0 |  |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowSlotTips/InputDisplay/Text | (0.00, 0.50)–(0.00, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | fitter(h=2 v=2) |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowSlotTips/InputDisplay/Sprites | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | 0.0 | fitter(h=2 v=2) |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowSlotTips/InputDisplay/Sprites/First | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/A.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowSlotTips/InputDisplay/Sprites/First/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowSlotTips/InputDisplay/Sprites/First/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowSlotTips/InputDisplay/Sprites/Spacer | (0.00, 1.00)–(0.00, 1.00) | (94.50, -41.00) | (5.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowSlotTips/InputDisplay/Sprites/Plus | (0.00, 1.00)–(0.00, 1.00) | (107.00, -41.00) | (69.00, 76.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/+.png_0.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowSlotTips/InputDisplay/Sprites/Second | (0.00, 1.00)–(0.00, 1.00) | (186.00, -41.00) | (82.00, 82.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/B.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowSlotTips/InputDisplay/Sprites/Second/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowSlotTips/InputDisplay/Sprites/Second/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardSlot/GamepadPromptHolder/GamepadPrompt/ShowSlotTips/Image | (0.50, 0.50)–(0.50, 0.50) | (93.10, 26.40) | (48.00, 40.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/op_info.png.asset |
