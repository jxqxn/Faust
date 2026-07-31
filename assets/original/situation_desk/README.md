# Situation Desk original assets

These files are original project assets generated for the first tabletop-map
presentation prototype. The two supplied *Grand Knights History* screenshots
were used only as visual references for painterly materials, warm map colours,
tabletop depth, and the separation between a map surface and physical pieces.
They were not used as edit targets, and no geography, UI, character, route,
node, logo, or pawn design was copied.

Generated with the built-in OpenAI image generator on 2026-07-31.

## `tabletop_campaign_map.png`

Final prompt:

> Production-ready 2D game environment texture for an original hand-painted
> fantasy strategy map. Ochre and moss-green terrain, wooded hills, mountain
> ridges, winding blue-green river, distant compact walled settlement, rocky
> highlands, and calm route-ready clearings. Watercolour and gouache with ink
> contours, worn parchment fibres, old-gold highlights, and a tactile printed
> board surface. Wide 16:9 near-top-down flat camera for runtime perspective.
> No text, labels, roads, nodes, characters, pawns, UI, frames, logos,
> trademarks, watermark, copied geography, or identifiable designs.

## `map_node_token.png`

Final prompt:

> One original circular physical route token, slightly elevated near-top-down,
> made from aged ivory stone with a narrow antique-brass rim and painterly
> handmade edges. Isolated on solid chroma green with no text, number, emblem,
> icon, cast shadow, reflection, UI, logo, watermark, or additional object.

The generated chroma background was removed locally with the image-generation
skill's `remove_chroma_key.py` helper using a soft matte, one-pixel contraction,
one-pixel feather, and green despill. The result was trimmed and placed on a
512×512 transparent canvas.

## `protagonist_pawn.png`

Final prompt:

> One original abstract traveller pawn in aged silver and dark bronze, with a
> tapered pedestal and a faceted lantern-like crown. Painterly cast-metal
> tabletop component, clearly not a knight helmet, chess knight, or copied
> existing piece. Isolated on solid chroma green with no text, human face,
> weapon, cast shadow, reflection, UI, logo, watermark, or extra object.

The generated chroma background was removed with the same soft-matte and
despill workflow, then trimmed and placed on a 512×512 transparent canvas.

The fantasy map is a non-canonical presentation study. Place names remain
runtime data and are deliberately not baked into any image asset.
