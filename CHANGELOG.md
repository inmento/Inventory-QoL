## 2026-10-04 — Gen1Recomp 0.3.51 compatibility refresh

## 2026-10-06 — Gen1Recomp 0.3.57 compatibility refresh
- Raised the manifest engine requirement to `>=0.3.57` while preserving any existing upper bound.
- Audited the Gen1Recomp v0.3.54–v0.3.57 release and source diff; no Gen 1/Gen 2 public hook or Mod API change used by this mod required a Lua code change.
- This is a compatibility metadata/documentation refresh; gameplay behavior, save formats, assets, and progression rules are unchanged.

- Updated the manifest engine requirement to `>=0.3.51` for the current Mod API 2 runtime.
- Revalidated the existing public hook/registry surface without changing gameplay behavior, assets, save formats, or progression rules.
- This entry is a compatibility maintenance update; install the matching release build before testing.

# Changelog

## 0.2.0 — Native Crystal support

- Adds **Pokémon Crystal** support for Gen1Recomp `0.2.24` and later through the existing shared Gen 2 PackMenu implementation; no gameplay or save-data behavior was changed solely for Crystal.
- Adds a Crystal loader smoke test that reads the official runtime metadata (`crystal` is Generation 2 with the `crystal` engine), then verifies that the `games: ["gen1", "gen2"]` manifest scope loads Inventory QoL and registers its `Gen2PackMenu` override.
- Updates player-facing documentation and manifest metadata to list Gold, Silver, and Crystal. The mod continues to package no game ROM data or assets.

## 0.1.3 — Useful Bag ticker layout compatibility

- Repairs the long TM/HM label ticker when **Useful Bag 2.4.1** and Inventory QoL are enabled together on the current Gen 1 Bag renderer.
- The repair is deliberately companion-scoped: it recognizes Useful Bag’s projected Bag instance, bypasses only its legacy direct label redraw, and redraws long labels within the actual Bag item rows using the current coordinates and clipping bounds.
- Useful Bag retains its pockets, L/R navigation, sorting, PC handling, hidden bag order, and battle-aware behavior. Inventory QoL remains unchanged when Useful Bag is absent, and Gold/Silver continue to use the normal Pack path.
- Adds a combined real-loader regression with an overflowing TM label, asserting that the ticker starts inside the Bag row rather than using the legacy border-overlapping coordinates.

## 0.1.2 — MAX action label and menu fit

- Replaces the clipped **USE MANY** bulk-use action with the concise **MAX** label in the Gen 1 Bag and Gen 2 Pack.
- Corrects the Gen 1 action menu after inserting the third row: it now grows from the vanilla two-row template to the required three-row height and recalculates its width from the actual action labels before drawing.
- Adds a Gen 2 Pack submenu renderer for the custom row so the player sees **MAX**, rather than the internal action identifier, while native action labels retain the engine’s normal layout.
- Adds regression coverage that checks every affected action label fits its Gen 1 or Gen 2 menu border, alongside the existing full Gen 1/Gen 2 and Useful Bag integration suite.

## 0.1.1 — Useful Bag compatibility

- Resolves the `screens already registered: BagMenu` load failure when **Useful Bag** is enabled with Inventory QoL.
- Declares Useful Bag as an optional dependency, ensuring its pocketed Gen 1 Bag factory loads before Inventory QoL.
- Wraps the already-registered Useful Bag factory instead of replacing it with the vanilla Bag. Useful Bag retains its six pockets, cycling, sorting, PC handling, and battle-aware behavior, while Inventory QoL applies its three-digit counts, cursor memory, and field-only `USE MANY` layer.
- Adds a real Mod API regression that loads both mods together and verifies the combined BagMenu, 999 stack limit, pocket projection, and cursor decoration.

## 0.1.0 — Initial release

- Raises normal item and Poké Ball stacks from 99 to **999**, while preserving existing pocket and slot limits.
- Adds safe three-digit quantity rendering to the Gen 1 Bag, Gen 2 Pack, and quantity selection UI.
- Remembers the Gen 1 Bag cursor and scroll position for the current session.
- Adds field-only **USE MANY** for Rare Candies, the full vitamin set, and PP Ups.
- Caps each batch to the selected Pokémon or move’s remaining legal improvement, preserving the original Gen 1/Gen 2 item rules.
- Keeps Poké Balls, temporary battle items, healing items, and other context-sensitive item classes one-at-a-time.
- Includes regression coverage for Red/Blue/Yellow and Gold/Silver routing, stack limits, three-digit layout, cursor memory, permanent-item caps, and stack hot-path performance.
