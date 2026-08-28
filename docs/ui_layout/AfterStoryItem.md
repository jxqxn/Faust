# UI layout manifest: Resources/prefab/AfterStoryItem.prefab

Corpus truth table (RectTransform, authored values). Regenerate with `tools/export_ui_layout.gd`.

Runtime mapping: `ui/over_new_after_story_item.gd` corresponds to
`OverNewAfterStoryItemController`; pages are ordered by `SortIndex`, then
`CardId` (`<Init>b__27_0`, RVA 0x588d40). `Bind` resets only the selected
page's vertical scroll position. Text and art are read directly from the
selected original `after_story` settlement and its saved/runtime `pic`.

Zoom mapping: `OverNewStep2StoryZoomController.ctor/UpdateSize`
(`0x57c8e0/0x57c190`) interpolates the parent widths from
`1707/1050/1000/1000` to `4800/3540/3740/3740` over the controller's
`ZoomTime=0.1`. At `Range=0.2` each item switches from the prefab's vertical
layout to reverse-horizontal: flexible text on the left, the source-preferred
`471x1028` illustration on the right. The root 3840x2160 canvas never moves.

## Nodes

| path | anchors | pos | size | pivot | scale | rotZ | extras |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AfterStoryItem | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (1000.00, 1900.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | layout(align=1 spacing=0.0 pad=[0, 0, 0, 0] cc=1/1 fe=0/0 rev=0) |
| AfterStoryItem/Icon | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=Resources/image/cards/2000001.asset |
| AfterStoryItem/Scroll View | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 0.50) | (1.00, 1.00) | 0.0 | sprite=guid:0000000000000000f000000000000000 |
| AfterStoryItem/Scroll View/Viewport | (0.00, 0.00)–(1.00, 1.00) | (0.00, 0.00) | (-20.00, 0.00) | (0.00, 1.00) | (1.00, 1.00) | -0.0 | sprite=guid:0000000000000000f000000000000000 |
| AfterStoryItem/Scroll View/Viewport/Content | (0.00, 1.00)–(1.00, 1.00) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 1.00) | (1.00, 1.00) | 0.0 | fitter(h=0 v=2) |
| AfterStoryItem/Scroll View/Viewport/Content/Text (TMP) | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (0.00, 0.00) | (0.50, 1.00) | (1.00, 1.00) | -0.0 | text="New TextaNew TextaNew Te…" fs=36 |
| AfterStoryItem/Scroll View/Scrollbar Vertical | (1.00, 0.00)–(1.00, 1.00) | (-10.00, -20.00) | (6.00, -40.00) | (1.00, 1.00) | (1.00, 1.00) | -0.0 | sprite=Sprite/scroll_bar.asset |
| AfterStoryItem/Scroll View/Scrollbar Vertical/Sliding Area | (0.00, 0.00)–(1.00, 1.00) | (0.50, 0.00) | (21.00, -10.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 |  |
| AfterStoryItem/Scroll View/Scrollbar Vertical/Sliding Area/Handle | (0.00, 0.00)–(0.00, 0.00) | (0.00, 0.00) | (0.00, 10.00) | (0.50, 0.50) | (1.00, 1.00) | -0.0 | sprite=Sprite/scroll_thumb.asset |
