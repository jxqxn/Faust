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
- `MapController.AddPin` is a UID-keyed dictionary insertion.  `OnDrop`
  forwards the card to `lastRite`; it does not open a location action menu.

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

## Current boundary

Implemented: original table/map textures, source location nodes and coordinates,
all static `RitePosition` children, range selection, same-child 100-pixel stack
offsets, UID-keyed clickable rite pins, and removal of the clone-only location
labels, count chits, area ratios, collision-ring layout, and location-selector
shortcut.  `tests/test_situation_desk_tabletop.gd` checks fixed/ranged selection
and the stacked offset from original content locations.

Still 🟡: `MapController.SetRitesPosition` runs a later global collision/bounds
pass over instantiated RiteControllers.  The source child choice and local
RitePosition stacking are exact; its separate final `SetPos` displacement rule
has not yet been mirrored or claimed.
