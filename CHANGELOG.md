# Changelog

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
