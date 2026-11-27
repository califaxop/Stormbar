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
| `/stb report` | Bugs & Feedback: the form's link and a line to paste into it |

## Good to know
- The swing timer needs WoW: Forever's swing event; without it, only the cast bar works.
- Positions aren't saved per Edit Mode layout.

## Updates
New versions come out every **Wednesday at 12:00 UTC** (8 PM Philippine time, 8 AM US Eastern). Urgent fixes ship sooner.

## Feedback
Found a bug, have feedback or want a feature? Click **Bugs & Feedback** at the top right of the settings window (or type `/stb report`): it gives you the form's link and, for a bug, a line to paste into it with everything we need. Or [open an issue](https://github.com/califaxop/stormbar/issues/new/choose) directly: there's a short form for each.

## Recent changes
- **1.4.0:** "Bugs & Feedback" now sits at the top right of the settings window, next to the ×. It opens a window (like Questie's trace export) with the form's link to copy at the top, for bug reports, feedback and feature requests, and for a bug, one line to paste into the form with your version, the game client, the bar's state, its settings and the cast bars it replaces; never your name, realm or guild. Also `/stb report`. The settings window is now solid and comes to the front when opened or clicked: with several addons' settings open, they no longer show through each other.
- **1.3.1:** Fixed: the settings window's text is readable with EllesmereUI installed (EllesmereUI's quest tracker shrinks the game's tracker fonts to 1 px, and the window used them). No style settings any more: the look follows EllesmereUI or FlareUI on its own whenever one is installed.
- **1.3.0:** EllesmereUI style when EllesmereUI is installed: flat bars with a thin black border in its font, and the settings window painted by EllesmereUI's own skinning API (its theme and accent colour). EllesmereUI style can be turned off under Look.
- **1.2.6:** Native look: the bar, its icon and the settings use the game's own tooltip border in bronze (without FlareUI style).
- **1.2.5:** Lighter: the time on the bar is redrawn only when it changes (10 times a second instead of every frame).
- **1.2.4:** The "Report a bug / suggest" link box is solid now and stays put over the settings window until you close it.
- **1.2.3:** New "Report a bug / suggest" button in the settings, linking to a short feedback form.
- **1.2.2:** No more "- No Text" after some object casts (e.g. "Opening").
- **1.2.1:** No more red flash for casts that go through at the last moment.
- **1.2.0:** New settings style; success flash with your own color.
- **1.1.0:** Choose which weapon's swing to track.
