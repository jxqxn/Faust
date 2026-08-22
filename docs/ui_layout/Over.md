# UI layout manifest: Resources/prefab/Over.prefab

Corpus truth table (RectTransform, authored values). Regenerate with `tools/export_ui_layout.gd`.

Runtime call chain: `OverNewController.Init` loads `OverNode`, starts at
`SHOW_OVER`, and `DoNext` moves through CG, optional story / after-story, then
`SHOW_RESULT`. `over.json` currently contains no `story` key, so the clone's
verified normal branch is `Step1 -> Step2(CG) -> Step3(result)`. `open_after_story`
does not itself create a story stage; it only gates the later transition after a
story stage. Evidence: `OverNewController.c` (`0x579f50`, `0x579bc0`),
`dump.cs` `OverNewController.Stage`, and direct `content/over.json` inspection.

The clone now uses the source `3840×2160` canvas and these stage names. Dynamic
title sprite selection and the `after_story` reader remain explicitly unported;
no replacement art is invented for the missing title atlas.

## Nodes

| path | anchors | pos | size | pivot | scale | rotZ | extras |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Over | (0.00, 0.00)–(1.00, 1.00) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Sprite/white.asset |
| Over/Step1 | (0.00, 0.00)–(1.00, 1.00) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| Over/Step1/Up Mask | (0.00, 0.50)–(1.00, 1.00) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 1.00) | (1.00, 1.00) | 0.0 | sprite=Sprite/white.asset |
| Over/Step1/Down Mask | (0.00, 0.00)–(1.00, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.00) | (1.00, 1.00) | 0.0 | sprite=Sprite/white.asset |
| Over/Step1/UIEffect | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (100.00, 100.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| Over/Step1/UIEffect/UIParticle | (0.50, 0.50)–(0.50, 0.50) | (0.00, -60.00) | (100.00, 100.00) | (0.50, 0.50) | (0.00, 0.00) | 0.0 |  |
| Over/Step1/Up Decorate | (0.50, 0.50)–(0.50, 0.50) | (0.00, 800.00) | (1232.00, 284.00) | (0.50, 0.00) | (1.00, 1.00) | 0.0 |  |
| Over/Step1/Down Decorate | (0.50, 0.50)–(0.50, 0.50) | (0.00, -800.00) | (1232.00, 284.00) | (0.50, 1.00) | (1.00, 1.00) | 0.0 |  |
| Over/Step1/Title BG | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (956.00, 1320.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| Over/Step1/Title BG/Title | (0.00, 0.50)–(1.00, 0.50) | (0.00, 140.00) | (-600.00, 160.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| Over/Step1/Title BG/Sub Title | (0.00, 0.50)–(1.00, 0.50) | (0.00, -10.00) | (-300.00, 200.00) | (0.50, 1.00) | (1.00, 1.00) | 0.0 |  |
| Over/Step1/Decorate | (0.50, 0.00)–(0.50, 1.00) | (0.00, 0.00) | (1888.24, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| Over/Step1/Decorate/UIParticle | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (100.00, 100.00) | (0.50, 0.50) | (0.00, 0.00) | 0.0 |  |
