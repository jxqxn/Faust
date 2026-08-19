# UI layout manifest: Resources/prefab/CardNew.prefab

Corpus truth table (RectTransform, authored values). Regenerate with `tools/export_ui_layout.gd`.

## Canvases

| name | scaler |
| --- | --- |
| GamepadPrompt | constant-pixel-size |
| Pop | constant-pixel-size |

## Nodes

| path | anchors | pos | size | pivot | scale | rotZ | extras |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CardNew | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (194.00, 422.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 |  |
| CardNew/Outline | (0.50, 0.50)–(0.50, 0.50) | (0.00, 22.00) | (256.00, 525.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Sprite/card_outline_new.asset |
| CardNew/Flash | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (256.00, 512.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Sprite/card_outline.asset |
| CardNew/GamepadPromptHolder | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (100.00, 100.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardNew/GamepadPromptHolder/GamepadPrompt | (1.00, 0.00)–(1.00, 1.00) | (15.00, -40.00) | (100.00, 322.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | layout(align=0 spacing=30.0 pad=[0, 0, 0, 0] cc=0/0 fe=0/0 rev=0) |
| CardNew/GamepadPromptHolder/GamepadPrompt/ChooseCard | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (54.00, 56.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardNew/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.50, 1.50) | 0.0 |  |
| CardNew/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Text | (0.00, 0.50)–(0.00, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | fitter(h=2 v=2) |
| CardNew/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Sprites | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | 0.0 | fitter(h=2 v=2) |
| CardNew/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Sprites/First | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/A.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Sprites/First/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Sprites/First/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Sprites/Spacer | (0.00, 1.00)–(0.00, 1.00) | (94.50, -41.00) | (5.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardNew/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Sprites/Plus | (0.00, 1.00)–(0.00, 1.00) | (107.00, -41.00) | (69.00, 76.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/+.png_0.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Sprites/Second | (0.00, 1.00)–(0.00, 1.00) | (186.00, -41.00) | (82.00, 82.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/B.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Sprites/Second/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/ChooseCard/InputDisplay/Sprites/Second/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/ChooseCard/Image | (0.50, 0.50)–(0.50, 0.50) | (84.00, 30.00) | (48.00, 52.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/op_hand.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/Hold | (0.00, 1.00)–(0.00, 1.00) | (40.00, -130.00) | (54.00, 56.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardNew/GamepadPromptHolder/GamepadPrompt/Hold/InputDisplay | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.50, 1.50) | 0.0 |  |
| CardNew/GamepadPromptHolder/GamepadPrompt/Hold/InputDisplay/Text | (0.00, 0.50)–(0.00, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | fitter(h=2 v=2) |
| CardNew/GamepadPromptHolder/GamepadPrompt/Hold/InputDisplay/Sprites | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (54.00, 56.00) | (0.00, 0.50) | (1.00, 1.00) | 0.0 | fitter(h=2 v=2) |
| CardNew/GamepadPromptHolder/GamepadPrompt/Hold/InputDisplay/Sprites/First | (0.00, 1.00)–(0.00, 1.00) | (0.00, -28.00) | (54.00, 56.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/A.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/Hold/InputDisplay/Sprites/First/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/Hold/InputDisplay/Sprites/First/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/Hold/InputDisplay/Sprites/Spacer | (0.00, 1.00)–(0.00, 1.00) | (94.50, -41.00) | (5.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardNew/GamepadPromptHolder/GamepadPrompt/Hold/InputDisplay/Sprites/Plus | (0.00, 1.00)–(0.00, 1.00) | (107.00, -41.00) | (69.00, 76.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/+.png_0.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/Hold/InputDisplay/Sprites/Second | (0.00, 1.00)–(0.00, 1.00) | (186.00, -41.00) | (82.00, 82.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/B.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/Hold/InputDisplay/Sprites/Second/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/Hold/InputDisplay/Sprites/Second/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/Hold/Image | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (100.00, 100.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/op_hand_hold.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/ShowCardInfo | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (54.00, 56.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardNew/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.50, 1.50) | 0.0 |  |
| CardNew/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Text | (0.00, 0.50)–(0.00, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | fitter(h=2 v=2) |
| CardNew/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Sprites | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | 0.0 | fitter(h=2 v=2) |
| CardNew/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Sprites/First | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/A.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Sprites/First/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Sprites/First/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Sprites/Spacer | (0.00, 1.00)–(0.00, 1.00) | (94.50, -41.00) | (5.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardNew/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Sprites/Plus | (0.00, 1.00)–(0.00, 1.00) | (107.00, -41.00) | (69.00, 76.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/+.png_0.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Sprites/Second | (0.00, 1.00)–(0.00, 1.00) | (186.00, -41.00) | (82.00, 82.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/B.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Sprites/Second/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/InputDisplay/Sprites/Second/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/ShowCardInfo/Image | (0.50, 0.50)–(0.50, 0.50) | (84.00, 26.00) | (48.00, 40.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/op_info.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/IThink | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (54.00, 56.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardNew/GamepadPromptHolder/GamepadPrompt/IThink/InputDisplay | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.50, 1.50) | 0.0 |  |
| CardNew/GamepadPromptHolder/GamepadPrompt/IThink/InputDisplay/Text | (0.00, 0.50)–(0.00, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | fitter(h=2 v=2) |
| CardNew/GamepadPromptHolder/GamepadPrompt/IThink/InputDisplay/Sprites | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | 0.0 | fitter(h=2 v=2) |
| CardNew/GamepadPromptHolder/GamepadPrompt/IThink/InputDisplay/Sprites/First | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/A.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/IThink/InputDisplay/Sprites/First/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/IThink/InputDisplay/Sprites/First/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/IThink/InputDisplay/Sprites/Spacer | (0.00, 1.00)–(0.00, 1.00) | (94.50, -41.00) | (5.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardNew/GamepadPromptHolder/GamepadPrompt/IThink/InputDisplay/Sprites/Plus | (0.00, 1.00)–(0.00, 1.00) | (107.00, -41.00) | (69.00, 76.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/+.png_0.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/IThink/InputDisplay/Sprites/Second | (0.00, 1.00)–(0.00, 1.00) | (186.00, -41.00) | (82.00, 82.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/B.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/IThink/InputDisplay/Sprites/Second/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/IThink/InputDisplay/Sprites/Second/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/IThink/Image | (0.50, 0.50)–(0.50, 0.50) | (84.70, 24.30) | (48.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/op_ithink.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/SplitCard | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (54.00, 56.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardNew/GamepadPromptHolder/GamepadPrompt/SplitCard/InputDisplay | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.50, 1.50) | 0.0 |  |
| CardNew/GamepadPromptHolder/GamepadPrompt/SplitCard/InputDisplay/Text | (0.00, 0.50)–(0.00, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | fitter(h=2 v=2) |
| CardNew/GamepadPromptHolder/GamepadPrompt/SplitCard/InputDisplay/Sprites | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | 0.0 | fitter(h=2 v=2) |
| CardNew/GamepadPromptHolder/GamepadPrompt/SplitCard/InputDisplay/Sprites/First | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/A.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/SplitCard/InputDisplay/Sprites/First/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/SplitCard/InputDisplay/Sprites/First/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/SplitCard/InputDisplay/Sprites/Spacer | (0.00, 1.00)–(0.00, 1.00) | (94.50, -41.00) | (5.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardNew/GamepadPromptHolder/GamepadPrompt/SplitCard/InputDisplay/Sprites/Plus | (0.00, 1.00)–(0.00, 1.00) | (107.00, -41.00) | (69.00, 76.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/+.png_0.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/SplitCard/InputDisplay/Sprites/Second | (0.00, 1.00)–(0.00, 1.00) | (186.00, -41.00) | (82.00, 82.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/B.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/SplitCard/InputDisplay/Sprites/Second/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/SplitCard/InputDisplay/Sprites/Second/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardNew/GamepadPromptHolder/GamepadPrompt/SplitCard/Image | (0.50, 0.50)–(0.50, 0.50) | (85.70, 22.80) | (48.00, 42.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/op_split.png.asset |
| CardNew/Pop | (0.00, 1.00)–(0.00, 1.00) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardNew/Pop/Pop From | (0.50, 0.50)–(0.50, 0.50) | (74.00, 23.10) | (84.00, 64.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Sprite/pop_from.asset |
| CardNew/Pop/Pop | (0.00, 1.00)–(0.00, 1.00) | (77.60, 64.40) | (675.01, 216.01) | (0.20, 0.00) | (1.00, 1.00) | -0.0 | fitter(h=2 v=2) |
| CardNew/Pop/Pop/bg | (0.00, 0.00)–(1.00, 1.00) | (10.00, -12.00) | (100.00, 80.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Sprite/pop_bg.asset |
| CardNew/Pop/Pop/Text (TMP) | (0.00, 1.00)–(0.00, 1.00) | (0.00, -216.01) | (675.01, 216.01) | (0.00, 0.00) | (1.00, 1.00) | 0.0 | text=""说点啥\n说点啥说点啥说点啥说点啥说点啥\n<…" fs=50 |
| CardNew/Pop/Pop/InputDisplay | (1.00, 0.00)–(1.00, 0.00) | (38.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.50, 1.50) | 0.0 |  |
| CardNew/Pop/Pop/InputDisplay/Text | (0.00, 0.50)–(0.00, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | fitter(h=2 v=2) |
| CardNew/Pop/Pop/InputDisplay/Sprites | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (54.00, 56.00) | (0.00, 0.50) | (1.00, 1.00) | 0.0 | fitter(h=2 v=2) |
| CardNew/Pop/Pop/InputDisplay/Sprites/First | (0.00, 1.00)–(0.00, 1.00) | (0.00, -28.00) | (54.00, 56.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/A.png.asset |
| CardNew/Pop/Pop/InputDisplay/Sprites/First/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardNew/Pop/Pop/InputDisplay/Sprites/First/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardNew/Pop/Pop/InputDisplay/Sprites/Spacer | (0.00, 1.00)–(0.00, 1.00) | (94.50, -41.00) | (5.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| CardNew/Pop/Pop/InputDisplay/Sprites/Plus | (0.00, 1.00)–(0.00, 1.00) | (107.00, -41.00) | (69.00, 76.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/+.png_0.asset |
| CardNew/Pop/Pop/InputDisplay/Sprites/Second | (0.00, 1.00)–(0.00, 1.00) | (186.00, -41.00) | (82.00, 82.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/B.png.asset |
| CardNew/Pop/Pop/InputDisplay/Sprites/Second/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| CardNew/Pop/Pop/InputDisplay/Sprites/Second/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| CardNew/Pop/Pop From | (0.50, 0.50)–(0.50, 0.50) | (74.00, 23.10) | (84.00, 64.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Sprite/pop_from.asset |
