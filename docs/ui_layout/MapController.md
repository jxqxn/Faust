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
  occupied `RitePosition` inside the inclusive 1-based range.
- `MapController.AddPin` is a UID-keyed dictionary insertion.  `OnDrop`
  forwards the card to `lastRite`; it does not open a location action menu.

Sources: `engine_spec/decompiled/MapController.c` (`Awake`, `AddPin`, `OnDrop`,
`SetPos`, `SetRitesPosition`), `GameController.c` (`GetLocation`,
`GetLocationRange`), `LocationController.c` (`Init`, `GetPosition`), and
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

## Current boundary

Implemented: original table/map textures, source location nodes and coordinates,
UID-keyed clickable rite pins, temporary visible collision separation, and removal of
the clone-only location labels, count chits, area ratios, and location-selector
shortcut.

Still unverified: the static scene's serialized `RitePosition` child transforms
were not recovered from the corpus.  Therefore pin **area origins** are source
exact, but their exact per-position child coordinate is 🟡.  Do not reinterpret
`location:[a,b]` as x/y; it is a least-occupied position-range selector.
