# MapController — source mapping and fidelity boundary

This is the source map presentation contract for `ui/map_controller.gd`.
It is not gameplay configuration and must not be turned into a new content
table.

## Original structure

- `MapController` owns `LocationPrefab`, `DesktopImage`, `MapImage`,
  `locations`, `maps`, `pins`, `lastRite`, `ViewRange`, and `DeskBGSpecial`.
  (`dump.cs` MapController, GameScene `MonoBehaviour &11384`.)
- `Awake` indexes the authored `LocationController[]` into `maps`; a mod can
  add/update locations through `ModGameNode.Map.locations`.
- `GameController.GetLocation` parses an original rite `location` string,
  resolves the named `LocationController`, then calls
  `LocationController.GetPosition(min,max)`.  That method selects the least
  occupied `RitePosition` inside the inclusive 1-based range; equal occupancy
  keeps the lower-numbered child.
- `RitePosition.AddRite` first normalises existing children, then parents the
  new rite at local `(riteCountAfterAdd * 100 - 100, 0, 0)`.  A location string
  is therefore a selector (`area:N` or `area:[N,M]`), never an x/y coordinate.
- `MapController.AddPin` is a **rite-definition-ID** keyed dictionary
  insertion. `Player.pins` is an ordered, de-duplicated `List<int>` of those
  IDs. `GameController.AddRite` instead makes a runtime-UID `RiteController`.
  `OnDrop` forwards the card to `lastRite`; it does not open a location action
  menu.

Sources: `engine_spec/decompiled/MapController.c` (`Awake`, `AddPin`, `OnDrop`,
`SetPos`, `SetRitesPosition`), `GameController.c` (`GetLocation`,
`GetLocationRange`), `LocationController.c` (`Init`, `GetPosition`), and
`RitePosition.c` (`AddRite`, `RemoveRite`, `UpdateExistsChild`), and
`il2cpp_dump/dump.cs` (`MapController`, `LocationController`, `RitePosition`).

## Authored static locations

`GameScene.unity` `Map` (`RectTransform &7621`) is `4200 x 2600`, scale `1.25`,
with local position `(0,-178)`.  The clone maps the following original child
RectTransforms directly; all positions are in source pixels, centred in the
Map coordinate space.

| GameObject | in-game name | position | size | active |
| --- | --- | --- | --- | --- |
| Palace | 宫廷 | (-477, 508) | 690×446 | yes |
| Treasure | 奇珍 | (-1238, 263) | 800×500 | yes |
| Enemy | 大敌 | (-1238, 263) | 800×500 | yes |
| Parish | 神殿区 | (-1414, 521) | 800×500 | yes |
| Outside | 野外 | (1380, 197) | 800×500 | yes |
| Blackstreet | 黑街 | (439, -70) | 800×500 | yes |
| Skill | 技能树 | (-1238, 263) | 800×500 | yes |
| SelfHome | 自宅 | (-1506, -141) | 321×211 | yes |
| Harem | 后宫 | (-1238, 263) | 800×500 | no |
| End | 结局 | (-1238, 263) | 800×500 | yes |
| Uptown | 上城区 | (-65, 768) | 723×383 | yes |
| Downtown | 商业区 | (-121, -133) | 800×500 | yes |

## Authored RitePosition children

The static child nodes are ordinary Unity `Transform`s, not `RectTransform`s;
the prior export only read the latter and therefore missed them.  Each child is
named `1` through `N` and carries the `RitePosition` MonoBehaviour.  The clone
now embeds these source coordinates directly in `LOCATION_SCENE_SPECS` as
presentation scene data, not as a gameplay content conversion.

| location | child count | source local positions, in child-number order |
| --- | ---: | --- |
| 宫廷 | 11 | (-87,-108), (104,58), (-264,7), (159,-220), (229,-55), (484,-174), (-164,-220), (-405,-108), (-213,122), (438,62), (11,257) |
| 奇珍 | 15 | (1117,714), (-152,33), (604,-1079), (2174,-237), (449,689), (2774,536), (2736,-941), (-583,570), (1287,-910), (1767,-1046), (3129,-777), (-167,-1122), (-922,569), (3140,566), (-802,-1171) |
| 大敌 | 6 | (1328,188), (1843,-713), (1928,-66), (2737,-791), (-79,163), (-531,-940) |
| 神殿区 | 11 | (-281,-2), (-467,-285), (310,32), (-419,-141), (120,166), (17,25), (-200,137), (146,313), (-737,-120), (-681,61), (-68,454) |
| 野外 | 15 | (32,403), (-353,99), (57,33), (-217,565), (-52,228), (-59,-98), (-460,-353), (-479,-484), (-129,-384), (-399,-634), (-276,-792), (-17,-572), (145,-258), (251,-418), (-501,310) |
| 黑街 | 20 | (147,287), (-139,-179), (-797,-251), (-887,-364), (-567,-420), (-478,-302), (-243,-412), (-141,-298), (-283,-71), (-211,206), (92,-52), (201,-175), (237,156), (-945,-137), (-603,-79), (-479,-188), (-72,92), (460,322), (501,447), (-129,-626) |
| 技能树 | 1 | (3465,-1461) |
| 自宅 | 14 | (24,3), (-295,11), (44,120), (338,-3), (106,-113), (82,234), (-211,-114), (-155,-242), (164,-248), (-280,173), (145,-389), (440,-532), (-637,-482), (-680,92) |
| 后宫 | 2 | (158,17), (41,59) |
| 结局 | 20 | (-904,-731), (1976,478), (0,-500), (830,-429), (1185,-32), (533,292), (673,138), (3038,148), (1102,-170), (726,-870), (554,-194), (900,539), (1488,1447), (1096,-489), (282,464), (2774,705), (2532,748), (1523,-859), (997,1782), (1546,1627) |
| 上城区 | 12 | (-675,-754), (-995,-706), (-764,-863), (-445,-864), (-580,-635), (-907,-588), (19,56), (409,-136), (398,-2), (-36,-78), (386,143), (482,-267) |
| 商业区 | 10 | (-232,-383), (95,-238), (4,8), (74,131), (-92,-108), (194,-113), (-269,-11), (284,1), (261,397), (337,-503) |

## RitePin geometry

`RitePin.prefab` is a separate object from `RiteNew.prefab`.  Its root remains
at the selected `RitePosition`; its `Icon` child is not root-centred: anchored
at `(0,-17.6)`, size `123×133`, pivot `(0.5,0)`.  The clone maps that exact
rectangle (including its visual centre offset) before applying the scene's map
coordinate conversion.  This is why a rite icon's centre is not identical to
the selected child Transform coordinate.

Sources: `Resources/prefab/RitePin.prefab` root/Icon RectTransforms
`&224256069497284392` / `&224632457200066912`, plus `dump.cs` `RitePinRender`.

## Current boundary

Implemented: original table/map textures, source location nodes and coordinates,
all static `RitePosition` children, range selection, same-child 100-pixel stack
offsets, and the two independent map object carriers:

- a runtime-UID, clickable `RiteNew` card for every live `Rite`, using its
  independently authored `bound` rectangle `(0,-18)`, `123×133`, pivot `(0.5,0)`;
- a non-interactive `RitePin` endpoint for each ordered, de-duplicated
  `Player.pins` definition ID, using its `(0,-17.6)`, `123×133`, pivot `(0.5,0)`
  Icon rectangle.

On settlement, the clone now removes the live runtime rite first and only then
adds its definition ID when `RiteNode.final_pin=true`, matching the result-panel
chain. `tests/test_situation_desk_tabletop.gd` checks the fixed/ranged card
selection, stack offset, card/pin split, and final-pin transition.

The currently exported `rites.png` atlas has some `rite_ex_*` metadata frames
outside its available bitmap bounds.  The clone still creates the source-backed
card/pin carrier and geometry, but intentionally leaves that unavailable source
texture blank; it does not substitute a hand-made image.  Direct Unity-GUID
asset extraction is the remaining asset-provenance task for those frames.

`SetRitesPosition` / `SetPos` is now mapped for `RiteNew` only: NORMAL or
range-location (`[`) cards sort by their bound centre's distance to the current
screen centre; the later card moves along its smaller overlap axis.  Fixed
special cards move only away from that primary group.  A candidate whose **bound
centre** leaves `bg` reverts to its whole previous position—there is no edge
clamp.  This is separate from `RitePosition`'s same-child 100-pixel stacking.
`RiteController.Init` selects that `RitePosition` once; redraw does not select
again. On removal, `RiteController.OnDestroy` invokes `RemoveRite`, whose
`UpdateExistsChild` compacts surviving siblings back to local `index×100`.

Still 🟡: `from_pins` line generation. The line data is present in 8 original
rite files and will remain a separate, source-backed layer rather than being
folded into pin or card placement.
