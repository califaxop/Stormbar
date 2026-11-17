# Stormbar
Your swing timer and cast bar, merged into one clean bar.

Stormbar shows your weapon swing timer with the icon of the weapon you're tracking. When you cast or channel, the cast bar takes its place with the spell's icon, then the swing timer returns. Swings come from Forever's own swing event, so the timer follows only your attacks.

Features
- Choose the weapon tracked: Main Hand, Off Hand, or Ranged (wands, guns, bows, thrown).
- Cast and channel bar with spell icon, name and time left; red flash on interrupt.
- FlareUI style when installed: its bronze borders, bar texture and swing colors.
- Can hide Blizzard's cast bar, FlareUI's Player Cast Bar, and FlareUI's swing bar for the same weapon.
- Move it in Edit Mode: drag, snap to Edit Mode's grid, arrow keys to nudge (Shift for 10 px), click for its options.

Settings and commands
- /stormbar or /stb: settings (weapon, scale, width, height, icon, time, hide when idle, FlareUI style, what to hide).
- Sliders move in steps of 1, with a box to type exact values.
- /stb lock / unlock, /stb reset, /stb debug.

Requirements
- WoW: Forever (client 16001). Optional: FlareUI.

Known limits
- The swing timer needs Forever's swing event; on a client without it, only the cast bar works.
- Positions are saved once, not per Edit Mode layout.

Changelogs
- 1.1.2: Released automatically from GitHub; no in-game changes.
- 1.1.1: Logo in the AddOns list.
- 1.1.0: Choose the tracked weapon: Main Hand, Off Hand or Ranged.
- 1.0.5: Arrow-key nudge in Edit Mode (Shift = 10 px).
- 1.0.4: Sliders in steps of 1 with number boxes; backdrop fit fixed.
- 1.0.3: Fixed the addon not loading (client version line).
- 1.0.2: Options dialog no longer moves while resizing.
- 1.0.1: Hides FlareUI's cast bar; bar drawn above FlareUI's.
- 1.0.0: Simplified to one merged swing timer and cast bar.
- 0.1.0 – 0.4.0: Early action bar builds with Edit Mode support.
