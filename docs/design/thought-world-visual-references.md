# Thought World visual reference and asset policy

## Target presentation

The lateral scene deliberately does not inherit the Sultan desk's palace,
parchment, or black-and-gold visual language. Its target is a painterly
late-1980s everyday city: warm sunset backlight, cool violet shadows,
semi-realistic full-body characters, deep foreground silhouettes, drifting
atmosphere, and sparse thought keywords arranged around the protagonist.

The reference is the presentation grammar of *13 Sentinels: Aegis Rim*, not
its copyrighted characters, backgrounds, footage, logos, or UI art. The
project ships only original generated production art and separately licensed
open assets.

## Primary references

- Official ATLUS product page and trailers:
  <https://atlus.com/13sentinels/lang/en/>
- Official SEGA Asia product page, including its description of the
  side-scrolling Remembrance mode and Thought Cloud:
  <https://asia.sega.com/13sar/cn/switch/>

Official screenshots and video remain external references and must not be
copied into the repository.

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

- Original background and four original protagonist poses:
  `assets/original/thought_world/`
- Two CC0 Kenney interface sounds:
  `assets/third_party/kenney_new_platformer_subset/audio/`
- Original procedural fog, grain, and vignette shader:
  `ui/shaders/thought_world_atmosphere.gdshader`
