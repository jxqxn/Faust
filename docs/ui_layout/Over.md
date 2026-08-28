# UI layout manifest: Resources/prefab/Over.prefab

Corpus truth table (RectTransform, authored values). Regenerate with `tools/export_ui_layout.gd`.

Runtime chain: `OverNewController.Init/DoNext` (0x579f50/0x579bc0) owns
the stage transition; `OverNewStep2StoryController.Init` (0x57b740,
state-machine body 0x5863e0) builds the story and after-story pages;
`OverNewAfterStoryItemController.Setup/Show` (0x578e70/0x5790a0/0x579620)
renders each selected settlement. `hasStory` comes from
`OverNode.text_extra.Length`; the callback `<DoInit>b__18_1` (0x57a510)
replaces the initial `open_after_story` flag with whether any concrete item was
created. Historical records with `player_data == null` replay the exact
`AfterStoryData.prior/extra` keys rather than re-evaluating current state.

The previous generated table contained only Step1 because it was captured
before the complete AssetRipper scan finished. This table was regenerated from
the same read-only `Over.prefab` and now includes Step2, Step2-Story, Step3 and
Blocker. The clone maps the controller and item classes 1:1. Story playback now
uses `PlaySpeed=20`, `CurrentVisibleCharacter += deltaTime * PlaySpeed`, TMP
integer truncation and `StopStory`'s first-activation reveal boundary; zoom uses
the source 0.1-second width interpolation and 0.2 layout-switch threshold.
Runtime evidence: `story_typewriter_screenshot.png` captures an original
`over.json` story while the 20-character/second reveal is still in progress.

## Nodes

| path | anchors | pos | size | pivot | scale | rotZ | extras |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Over | (0.00, 0.00)–(1.00, 1.00) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Sprite/white.asset |
| Over/Step3 | (0.00, 0.00)–(1.00, 1.00) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Sprite/bg_new.asset |
| Over/Step3/Logo | (0.50, 0.50)–(0.50, 0.50) | (0.00, 800.00) | (1460.00, 916.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/logo/logo_zhCN.asset |
| Over/Step3/Seperator | (0.50, 0.50)–(0.50, 0.50) | (0.00, 300.00) | (703.00, 6.00) | (0.50, 0.50) | (3.00, 1.00) | 0.0 | sprite=Sprite/seperator_0.asset |
| Over/Step3/Content | (0.50, 0.50)–(0.50, 0.50) | (0.00, 103.00) | (2000.00, 50.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| Over/Step3/PointPlus | (0.00, 0.50)–(1.00, 0.50) | (0.00, -120.00) | (3840.00, 100.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| Over/Step3/PointPlus/Icon | (0.49, 0.50)–(0.49, 0.50) | (40.00, 0.00) | (103.00, 110.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Sprite/point_0.asset |
| Over/Step3/PointPlus/Text (TMP) | (0.51, 0.50)–(0.51, 0.50) | (80.00, 0.00) | (199.00, 50.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| Over/Step3/Seperator (1) | (0.50, 0.50)–(0.50, 0.50) | (0.00, -343.00) | (703.00, 6.00) | (0.50, 0.50) | (3.00, 1.00) | 0.0 | sprite=Sprite/seperator_0.asset |
| Over/Step3/Back | (0.50, 0.50)–(0.50, 0.50) | (0.00, -510.00) | (810.00, 348.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 |  |
| Over/Step3/Back/Outline | (0.50, 0.00)–(0.50, 0.00) | (0.00, 80.84) | (380.00, 56.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Sprite/rite_title.asset |
| Over/Step3/Back/Image | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (668.00, 140.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Sprite/button_bg_new.asset |
| Over/Step3/Back/Text (TMP) | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (400.00, 50.00) | (0.50, 0.50) | (2.00, 2.00) | -0.0 |  |
| Over/Step3/Back/Text Hghlight | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (400.00, 50.00) | (0.50, 0.50) | (2.00, 2.00) | -0.0 |  |
| Over/Step2 | (0.00, 0.00)–(1.00, 1.00) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| Over/Step2/CG | (0.00, 0.00)–(1.00, 1.00) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 |  |
| Over/Step2/Mask | (0.00, 0.00)–(1.00, 1.00) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Sprite/after_story_tile_mask.asset |
| Over/Step2/Mask/UIParticle | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (100.00, 100.00) | (0.50, 0.50) | (0.00, 0.00) | 0.0 |  |
| Over/Step2/Over Title | (0.00, 0.00)–(0.00, 0.00) | (100.00, 100.00) | (100.00, 100.00) | (0.00, 0.00) | (1.00, 1.00) | 0.0 |  |
| Over/Step2/Over Title/BG | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (4000.00, 100.00) | (0.00, 0.50) | (1.00, 1.00) | 0.0 | layout(align=3 spacing=10.0 pad=[8, 0, 0, 0] cc=1/0 fe=0/0 rev=0) |
| Over/Step2/Over Title/BG/BG | (0.00, 0.50)–(0.00, 0.50) | (0.00, 0.00) | (800.00, 80.00) | (0.00, 0.50) | (1.00, 1.00) | 0.0 | sprite=Sprite/after_story_title_board.asset |
| Over/Step2/Over Title/BG/Border | (0.00, 0.50)–(0.00, 0.50) | (14.50, 0.00) | (13.00, 80.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Sprite/after_story_title_bg.asset |
| Over/Step2/Over Title/BG/Title | (0.00, 0.00)–(1.00, 1.00) | (20.00, 0.00) | (-40.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | layout(align=3 spacing=30.0 pad=[0, 0, 0, 0] cc=0/0 fe=0/0 rev=0) |
| Over/Step2/Over Title/BG/Title/Title | (0.00, 1.00)–(0.00, 1.00) | (0.00, -50.00) | (0.00, 80.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | fitter(h=2 v=0) |
| Over/Step2/Over Title/BG/Title/Content | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (30.00, 100.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | layout(align=0 spacing=10.0 pad=[0, 0, 0, 0] cc=0/0 fe=0/0 rev=0) |
| Over/Step2-Story | (0.00, 0.00)–(1.00, 1.00) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| Over/Step2-Story/BG | (1.00, 0.00)–(1.00, 1.00) | (0.00, 0.00) | (1707.00, 0.00) | (1.00, 0.50) | (1.00, 1.00) | 0.0 | sprite=Sprite/after_story_content_bg.asset |
| Over/Step2-Story/Story View | (1.00, 0.00)–(1.00, 1.00) | (-150.00, 0.00) | (1050.00, -400.00) | (1.00, 0.50) | (1.00, 1.00) | 0.0 | sprite=guid:0000000000000000f000000000000000 fitter(h=0 v=0) |
| Over/Step2-Story/Story View/Viewport | (0.00, 0.00)–(1.00, 1.00) | (0.00, 0.00) | (-17.00, 0.00) | (0.00, 1.00) | (1.00, 1.00) | -0.0 | sprite=guid:0000000000000000f000000000000000 |
| Over/Step2-Story/Story View/Viewport/Content | (0.00, 1.00)–(1.00, 1.00) | (0.00, 0.00) | (0.00, 520.00) | (0.00, 1.00) | (1.00, 1.00) | -0.0 | fitter(h=0 v=2) |
| Over/Step2-Story/Story View/Viewport/Content/Front Spacer | (0.00, 1.00)–(0.00, 1.00) | (546.50, -150.00) | (893.00, 300.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 |  |
| Over/Step2-Story/Story View/Viewport/Content/Title | (0.00, 1.00)–(0.00, 1.00) | (546.50, -390.00) | (893.00, 180.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| Over/Step2-Story/Story View/Viewport/Content/Spacer | (0.00, 1.00)–(0.00, 1.00) | (546.50, -500.00) | (893.00, 40.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 |  |
| Over/Step2-Story/Story View/Viewport/Content/Story | (0.00, 1.00)–(0.00, 1.00) | (546.50, -520.00) | (893.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| Over/Step2-Story/Story View/Scrollbar Vertical | (1.00, 0.00)–(1.00, 1.00) | (0.00, -200.00) | (6.00, -400.00) | (1.00, 1.00) | (1.00, 1.00) | -0.0 | sprite=Sprite/scroll_bar.asset |
| Over/Step2-Story/Story View/Scrollbar Vertical/Sliding Area | (0.00, 0.00)–(1.00, 1.00) | (0.50, 0.00) | (21.00, -10.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 |  |
| Over/Step2-Story/Story View/Scrollbar Vertical/Sliding Area/Handle | (0.00, 0.63)–(1.00, 1.00) | (0.00, -10.00) | (0.00, -10.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Sprite/scroll_thumb.asset |
| Over/Step2-Story/Story View Blocker | (1.00, 0.00)–(1.00, 1.00) | (-50.00, 0.00) | (1000.00, -400.00) | (1.00, 0.50) | (1.00, 1.00) | 0.0 |  |
| Over/Step2-Story/After Story | (1.00, 0.00)–(1.00, 1.00) | (-50.00, -50.00) | (1000.00, -300.00) | (1.00, 0.50) | (1.00, 1.00) | 0.0 |  |
| Over/Step2-Story/After Story/Viewport | (0.00, 0.00)–(1.00, 1.00) | (0.00, 50.00) | (0.00, -100.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=guid:0000000000000000f000000000000000 |
| Over/Step2-Story/After Story/Viewport/Content | (0.00, 0.00)–(0.00, 1.00) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | fitter(h=2 v=0) |
| Over/Step2-Story/After Story/Op Contents | (0.00, 0.00)–(1.00, 0.00) | (0.00, -100.00) | (0.00, 200.00) | (0.50, 0.00) | (1.00, 1.00) | 0.0 |  |
| Over/Step2-Story/After Story/Op Contents/Prev | (0.50, 0.50)–(0.50, 0.50) | (-200.00, 9.00) | (168.00, 156.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Sprite/page_left_0.asset |
| Over/Step2-Story/After Story/Op Contents/Confirm | (1.00, 0.50)–(1.00, 0.50) | (20.00, -10.00) | (44.00, 51.00) | (1.00, 1.00) | (1.00, 1.00) | -0.0 | sprite=Sprite/jump.asset |
| Over/Step2-Story/After Story/Op Contents/Confirm/Text (TMP) | (0.50, 0.50)–(0.50, 0.50) | (-41.80, 0.00) | (100.00, 52.00) | (1.00, 0.50) | (1.00, 1.00) | 0.0 |  |
| Over/Step2-Story/After Story/Op Contents/Next | (0.50, 0.50)–(0.50, 0.50) | (200.00, 9.00) | (168.00, 156.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Sprite/page_right.asset |
| Over/Step2-Story/Jump | (1.00, 0.00)–(1.00, 0.00) | (-660.00, 170.00) | (44.00, 51.00) | (1.00, 1.00) | (1.00, 1.00) | -0.0 | sprite=Sprite/jump.asset |
| Over/Step2-Story/Jump/Text (TMP) | (0.50, 0.50)–(0.50, 0.50) | (-41.80, 0.00) | (100.00, 52.00) | (1.00, 0.50) | (1.00, 1.00) | 0.0 |  |
| Over/Step2-Story/Zoom | (1.00, 1.00)–(1.00, 1.00) | (-200.00, -60.00) | (93.00, 93.00) | (1.00, 1.00) | (1.00, 1.00) | -0.0 | sprite=Sprite/expand.asset |
| Over/Step2-Story/Zoom/InputDisplay | (0.50, 0.50)–(0.50, 0.50) | (40.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.50, 1.50) | 0.0 |  |
| Over/Step2-Story/Zoom/InputDisplay/Text | (0.00, 0.50)–(0.00, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | fitter(h=2 v=2) |
| Over/Step2-Story/Zoom/InputDisplay/Sprites | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | 0.0 | fitter(h=2 v=2) |
| Over/Step2-Story/Zoom/InputDisplay/Sprites/First | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (0.00, 0.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/A.png.asset |
| Over/Step2-Story/Zoom/InputDisplay/Sprites/First/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| Over/Step2-Story/Zoom/InputDisplay/Sprites/First/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
| Over/Step2-Story/Zoom/InputDisplay/Sprites/Spacer | (0.00, 1.00)–(0.00, 1.00) | (94.50, -41.00) | (5.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
| Over/Step2-Story/Zoom/InputDisplay/Sprites/Plus | (0.00, 1.00)–(0.00, 1.00) | (107.00, -41.00) | (69.00, 76.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/+.png_0.asset |
| Over/Step2-Story/Zoom/InputDisplay/Sprites/Second | (0.00, 1.00)–(0.00, 1.00) | (186.00, -41.00) | (82.00, 82.00) | (0.00, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/B.png.asset |
| Over/Step2-Story/Zoom/InputDisplay/Sprites/Second/Hold | (1.00, 0.00)–(1.00, 0.00) | (5.00, 10.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/hold_empty.png.asset |
| Over/Step2-Story/Zoom/InputDisplay/Sprites/Second/Hold/Fill | (0.50, 0.50)–(0.50, 0.50) | (0.00, 0.00) | (50.00, 46.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Resources/image/hold_full.png.asset |
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
| Over/Blocker | (0.00, 0.00)–(1.00, 1.00) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 |  |
