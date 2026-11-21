# Stormbar

**Your swing timer and cast bar, merged into one clean bar.**

Swing timer while you fight, cast bar while you cast, then right back to the swing. One bar, no clutter.

## Highlights
- **Swing timer:** Main Hand, Off Hand or Ranged, with your weapon's icon.
- **Cast bar:** spell icon, name and time left; channels included.
- **Clear feedback:** flashes your success color when a cast goes off, red when it's interrupted.
- **FlareUI style:** matches FlareUI's borders and bars when installed.
- **Replaces clutter:** can hide Blizzard's and FlareUI's cast and swing bars.
- **Edit Mode:** drag, snap to grid, nudge with arrow keys, click for options.

## Quick start
1. Type `/stormbar` (or `/stb`) and pick your weapon.
2. Open Edit Mode to move the bar.

## Commands
| Command | Does |
|---|---|
| `/stb` | Open settings |
| `/stb unlock` / `lock` | Move the bar without Edit Mode |
| `/stb reset` | Reset its position |
| `/stb debug` | Show what the bar sees |

## Good to know
- The swing timer needs WoW: Forever's swing event; without it, only the cast bar works.
- Positions aren't saved per Edit Mode layout.

## Feedback
Found a bug or have an idea? [Open an issue](https://github.com/califaxop/stormbar/issues/new/choose): there's a short form for each. The settings window has a "Feedback" button with this link too.

## Recent changes
- **1.2.6:** Native look: the bar and its icon use the game's own tooltip border (without FlareUI style).
- **1.2.5:** Lighter: the time on the bar is redrawn only when it changes (10 times a second instead of every frame).
- **1.2.4:** The "Report a bug / suggest" link box is solid now and stays put over the settings window until you close it.
- **1.2.3:** New "Report a bug / suggest" button in the settings, linking to a short feedback form.
- **1.2.2:** No more "- No Text" after some object casts (e.g. "Opening").
- **1.2.1:** No more red flash for casts that go through at the last moment.
- **1.2.0:** New settings style; success flash with your own color.
- **1.1.0:** Choose which weapon's swing to track.
