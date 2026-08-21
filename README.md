# Inventory QoL

**Inventory QoL** is a standalone Gen1Recomp Mod API 2 mod for **Red, Blue, Yellow, Gold, and Silver**. It raises normal item stacks from 99 to **999**, renders three-digit quantities without hiding the multiplier glyph, remembers the Gen 1 Bag cursor for the current session, and adds a cap-aware field-only **USE MANY** action for permanent progression items.

The mod deliberately does **not** turn every item into a bulk action. Poké Balls remain one throw at a time, and temporary battle items retain their ordinary one-turn behavior.

## Features

| Feature | Behavior |
|---|---|
| **999 normal-item stacks** | Normal items and Poké Balls can hold up to 999 copies per item ID. Existing bag pockets and slot limits stay unchanged. Key items, HMs, and badges remain singular. |
| **Three-digit quantity UI** | Counts from `×100` to `×999` render without overwriting the `×` glyph in the Gen 1 Bag, Gen 2 Pack, or shared quantity selector. |
| **Gen 1 cursor memory** | Closing and reopening the Bag restores its last selection and scroll position for the current play session. This UI state is never written into the save. Gold and Silver retain the engine’s existing per-pocket cursor behavior. |
| **USE MANY** | Permanent progression items gain a field-only `USE MANY` row alongside normal `USE` and `TOSS` behavior. |

## Cap-aware batch items

The amount selector appears **after choosing the target**, so its upper bound comes from that specific Pokémon or move rather than from a generic number. The mod uses the games’ original permanent-item rules.

| Item family | Included items | Selector maximum |
|---|---|---|
| **Rare Candy** | `RARE_CANDY` | The smaller of the amount owned and the chosen Pokémon’s remaining levels to 100. |
| **Vitamins** | `HP_UP`, `PROTEIN`, `IRON`, `CARBOS`, `CALCIUM`, `ZINC` | The smaller of the amount owned and the legal number of 2,560-point pre-Generation III stat-experience applications before that stat reaches its 25,600 threshold. |
| **PP Up** | `PP_UP` | The smaller of the amount owned and the selected move’s remaining applications before three PP Ups. `SKETCH` and already-maxed moves remain ineligible. |

> **Rare Candy batches preserve interactive progression.** The mod applies only legal levels and keeps normal level-up move-learning and evolution handling. If an interactive move or evolution screen is needed, the batch waits for that native interaction before it continues.

## Deliberate exclusions

| Item type | Why it remains one-at-a-time |
|---|---|
| Poké Balls | A battle permits one throw per item action and per turn. |
| X-items and other temporary battle items | Their effects are temporary battle stages rather than permanent progression. |
| Healing, status-curing, revive, PP-restoring, and repel items | Their proper stopping point depends on changing HP, status, PP, or overworld state. |
| Evolution stones, TMs, HMs, key items, rods, and registered field tools | These have distinct native interaction, consumption, or permanence rules. |

## Installation

1. Download the latest **Inventory-QoL.zip** release asset.
2. Install it through Gen1Recomp’s normal mod installer, then enable **Inventory QoL** in the selected profile.
3. Open the Bag or Pack normally. No new game is required; existing stacks and saves remain usable.

The mod requires **Gen1Recomp 0.2.14 or later** and Mod API 2.

## Testing performed

The release validation suite checks the real Mod API loader in both generations, the 999 stack cap, Gen 1 and Gen 2 three-digit display coordinates, Gen 1 cursor memory, PP Up limits, vitamin arithmetic, Rare Candy level caps, and a 999-stack hot path. The hot-path regression completes 999,000 existing-stack additions without a per-add bag scan.

## Compatibility

Inventory QoL only changes item-stack limits, Bag/Pack presentation, and the field submenu for the listed permanent consumables. It does not require any other mod. It should remain compatible with mods that add normal item entries, provided they use the engine’s standard `Bag.add` path.

Because the mod intentionally replaces the stock Bag and Pack screen factories, a separate mod that also replaces **the same entire screen IDs** will need explicit compatibility testing.

## License

MIT License. See [LICENSE](LICENSE).
