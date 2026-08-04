# Thought World visual reference and asset policy

## Target presentation

The lateral scene belongs to the same illustrated world as the tilted campaign
desk: a restrained hand-painted fantasy landscape, grounded full-body figures,
clear foreground/midground/background separation, and paper, wood and aged
metal interface materials. Moving from the desk pawn into a local scene should
feel like bringing one area of the tabletop illustration closer.

The active prototype uses original painted raster assets. They establish the
walk plane, actor scale, scene depth and shared palette without declaring a
nation, era, faction or story setting. The backgrounds and actors adopt a
Japanese 2D fantasy-game presentation while remaining project-original.

## Design boundary

The lateral scene is a presentation and interaction probe.
It is not the project's innovation claim. Its job is to make embodiment,
place and time legible. A visual match
does not prove that the single-character simulation works.

The current working direction is defined in
`docs/design/single-character-will-simulation.md`. Sultan rites and cards may
continue to appear here as technical placeholders, but their presence only
verifies the existing runtime chain.

## Reference hierarchy

- *Unicorn Overlord* is the primary visual reference for hand-drawn fantasy
  materials, grounded character scale, lateral encounter staging and the
  continuity between field, encounter and interface:
  <https://asia.sega.com/unicorn-overlord/cn/system/>
- *Grand Knights History* remains the structural reference for a physical pawn
  moving through an illustrated tabletop map.

The 13 Sentinels-style scene thought cloud / thought mode has been removed;
nearby dialogue remains a scene interaction.

Official and Wiki screenshots remain external references and must not be
copied into the repository. When generated art uses them directly, every input
is labeled as a style/composition reference and the prompt must forbid copied
characters, equipment, crests, UI, text, locations and screenshot layouts.
This applies to characters as well as environments: project-original character
art anchors identity and pose, while the external screenshots may only guide
brushwork, proportions, material response, stage lighting and palette.

## Implemented stage grammar

The active scene is no longer one wallpaper behind two sprites. It uses five
explicit presentation layers:

1. a slow-panning painted backplate;
2. procedural atmosphere and depth grading;
3. world-positioned actors with ground shadows;
4. a faster-panning transparent foreground that can cover feet and props;
5. an independent highland-leaf or river-mist environment loop.

The protagonist moves through a virtual stage wider than the viewport. Camera
tracking keeps the active actor inside a readable central band, dialogue
temporarily frames both speakers, and exits use a short staged transition.
Reduced-motion mode snaps camera and environmental loops to their stable
presentation.

## Open implementation references

- Godot demo projects (MIT), for 2D/parallax scene architecture:
  <https://github.com/godotengine/godot-demo-projects>
- Godot Shaders `2D Fog Overlay` (shader snippets CC0), used as a conceptual
  starting point for the project's original procedural atmosphere shader:
  <https://godotshaders.com/shader/2d-fog-overlay-2/>
- Poly Haven `Industrial Sunset` (CC0), retained as a lighting and fallback
  panorama reference but not currently bundled:
  <https://polyhaven.com/a/industrial_sunset>

## Current bundled assets

- Original painted PNG backgrounds and transparent character poses:
  `assets/original/thought_world/`
- Two CC0 Kenney interface sounds:
  `assets/third_party/kenney_new_platformer_subset/audio/`
- Original procedural fog, grain, and vignette shader:
  `ui/shaders/thought_world_atmosphere.gdshader`
