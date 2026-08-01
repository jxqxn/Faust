# Thought World original art

The active lateral-scene prototype uses original generated production art. No
active scene asset is extracted from or copied from another game.

## Active painted fantasy set (2026-08-01)

- `hilltop_waystation_stage.png`: wide hilltop waystation backplate.
- `hilltop_waystation_foreground.png`: transparent grass, stone and timber
  occlusion layer.
- `river_road_stage.png`: wide river-road and bridge backplate.
- `river_road_foreground.png`: transparent reeds, rocks and fence occlusion
  layer.
- `protagonist_traveler_*.png`: one generic JRPG traveler in idle, thought and
  two walk-key poses.
- `traveling_companion.png`: a generic traveling companion used by the
  proximity-dialogue probe.

The foreground sources were generated on a flat magenta key, removed locally
with the installed ImageGen chroma-key helper, and checked for transparent
corners. Characters also retain a shared 1:2 canvas so their runtime baseline
does not jump between poses.

## External reference images

The 2026-08-01 backplates, foregrounds, and final character set used screenshots
from the following pages as direct ImageGen style/composition inputs:

- PlayStation product screenshots (lateral battle and dialogue staging):
  <https://www.playstation.com/en-ie/games/unicorn-overlord/>
- Sega's official Chinese system pages and embedded gameplay videos:
  <https://asia.sega.com/unicorn-overlord/cn/system/explore/>
  <https://asia.sega.com/unicorn-overlord/cn/system/stage-battle/>
- Unicorn Overlord community Wiki images (map terrain and painted character
  material reference):
  <https://unicornoverlord.fandom.com/wiki/Unicorn_overlord_Wiki>

Reference downloads were kept outside the project and are not bundled. Their
roles were limited to brushwork, atmospheric depth, palette, full-body scale,
side-view blocking, and foreground overlap. The project's earlier generic
traveler images were supplied only as identity and pose anchors when producing
the final character set.

## Final ImageGen prompt set

All production prompts explicitly identified the supplied screenshots as
*Unicorn Overlord* references and repeated this invariant:

> Use the supplied Unicorn Overlord screenshots only as visual references for
> painterly material rendering, layered side-view stage composition,
> atmospheric depth, and grounded walk-plane readability. Do not reproduce
> any identifiable character, location, building, crest, interface, object,
> screenshot composition, text, logo, emblem, flag, or UI. All visual content
> must be newly designed and project-original.

### Hilltop backplate

> Original very-wide 16:9 Japanese 2D fantasy strategy-RPG environment: a
> generic hilltop stone waystation and broad road at late afternoon, distant
> green valleys and mountain ridges, hand-painted gouache/watercolor texture,
> moss green, ochre, old gold and blue-gray distance. Camera at human
> waist-to-chest height, strong far/middle/walk-plane separation, open space
> for two full-body characters, no people, creatures, vehicles, text or UI.

### River-road backplate

> Original very-wide 16:9 Japanese 2D fantasy strategy-RPG environment: a
> generic riverside trade road, shallow stone bridge, weathered waymarker,
> reeds, willow silhouettes and distant ruins at blue-gold dusk. Hand-painted
> gouache/watercolor texture, cool haze over water, clear horizontal walk
> plane and open character space; no people, creatures, vehicles, text or UI.

### Foreground occlusion layers

> A separate low near-camera strip matching the supplied project-original
> backplate: irregular grass/reeds, stone, branches and one cropped timber
> prop, with large gaps for readable characters and taller clusters only at
> the edges. Paint on one perfectly flat `#ff00ff` chroma-key background with
> no gradient, texture, shadow, fog, floor plane or reflection. No people,
> animals, text, UI, logo, emblem or copied game object.

### Protagonist identity and pose set

> Create an entirely original, common JRPG male traveler. Preserve the supplied
> project-original identity anchor: short black hair, practical dark brown and
> muted olive travel coat, off-white shirt, leather satchel, trousers and
> sturdy boots. Use the supplied official *Unicorn Overlord* gameplay screenshot
> only for hand-painted anime rendering, softly modeled fabric and leather,
> restrained outlines, warm natural rim light, readable side-view proportions
> and illustrated-diorama finish. Do not reproduce or resemble an identifiable
> character, face, hairstyle, costume, armor, weapon, heraldry, emblem, color
> scheme, location, text, logo or UI. Generic civilian traveler; no weapon,
> armor or magic. Produce a neutral idle, a chin-resting thought pose, and two
> complementary natural walk-cycle poses on flat `#ff00ff`.

### Traveling companion

> Create an entirely original, common JRPG traveling merchant/scout companion:
> tied-back auburn hair, muted teal travel dress/tunic, short weathered brick-red
> shoulder cape, leather belt, satchel and sturdy boots. Use the supplied
> official gameplay screenshot only for painterly side-view rendering and the
> supplied Wiki gameplay image only for its restrained earth, teal and warm-gold
> palette relationship. Do not copy any identifiable person, costume, equipment,
> heraldry, location, icon, layout, text or UI. Friendly grounded civilian; no
> staff, weapon, armor or magic; flat `#ff00ff` background.

## Runtime boundary

The runtime intentionally retains the legacy `school_rooftop`, `riverbank`,
`from_rooftop` and `from_riverbank` data keys so existing v5 saves continue to
load. Those keys no longer describe player-facing content. Art is separated
into backdrop, atmosphere, actors, foreground occlusion and environment-loop
layers; camera and parallax transforms remain presentation-only.

The superseded campus backgrounds, school-uniform studies, and the first
single-layer fantasy backplates were removed so they cannot become runtime
fallbacks.
