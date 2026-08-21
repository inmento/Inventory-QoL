# Changelog

## 0.1.0 — Initial release

- Raises normal item and Poké Ball stacks from 99 to **999**, while preserving existing pocket and slot limits.
- Adds safe three-digit quantity rendering to the Gen 1 Bag, Gen 2 Pack, and quantity selection UI.
- Remembers the Gen 1 Bag cursor and scroll position for the current session.
- Adds field-only **USE MANY** for Rare Candies, the full vitamin set, and PP Ups.
- Caps each batch to the selected Pokémon or move’s remaining legal improvement, preserving the original Gen 1/Gen 2 item rules.
- Keeps Poké Balls, temporary battle items, healing items, and other context-sensitive item classes one-at-a-time.
- Includes regression coverage for Red/Blue/Yellow and Gold/Silver routing, stack limits, three-digit layout, cursor memory, permanent-item caps, and stack hot-path performance.
