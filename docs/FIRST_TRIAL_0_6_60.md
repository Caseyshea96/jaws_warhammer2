# First outside trial fixes 0.6.60 — October 30, 2026

Feedback from trial run 1 on the owner's friend's PC (0.6.59):

1. New Campaign said "Could not verify this screen. Press F2 and try again."
2. Continue Campaign said "Not supported yet." (Enter and Space alike.)
3. TW Mod Manager is hard to use with NVDA to start the game with the mod.

## Causes

- **Main menu / Select Campaign activation compared the whole screen with a
  recording from this PC**: exact node counts (main menu 86/87, Select
  Campaign 167/168) and every label, tooltip and state. Any other PC (DLC,
  saves, news banner, version, language) fails, so New Campaign was refused.
  Select Campaign was also classified "not supported" unless the root had
  exactly the children and particle effects seen here.
- Continue Campaign (`button_start_campaign`) was not an allowed target.
- The companion's launch used `steam://rungameid/594570`, which opens TW Mod
  Manager.

## Changes

- **Identity check instead of a recording** (`activate_player_target` in
  `diagnostics/graphics_preview.lua`): on the main menu and Select Campaign the
  selected element is clicked when its ID is allowed (`button_new_campaign`,
  `button_start_campaign` = Continue Campaign, `button_graphics`,
  `button_next` = Continue) and, read again at the press, it is the same
  element: same IDs and addresses on its path, every read on the path
  successful, visible, same label and tooltip, interactive and `active`; no
  visible or unreadable extra root panel (a dialog); and nothing read on the
  screen changed between the selection read and the press read (a DLC purchase
  panel appearing, a changed selection or title cancels). Not compared:
  visibility of unnamed particle effects, the tooltip/news layers' contents.
  A lookalike element elsewhere is never the target (the selected path is).
  Mortal Empires selected (remembered by the game) may continue.
- Select Campaign is supported unless a visible extra panel is on top.
- Continue Campaign loads the latest save; "Continue Campaign is unavailable."
  when there is none. Load Campaign stays "Not supported yet." (its save list
  is not read).
- **Campaign HUD reading starts on for players** once the map is read
  (`"source":"player-default"`); Shift+F2 still switches to map controls and a
  player's choice is kept. Before, a player had to know Shift+F2 before any key
  read the HUD (developer verify mode had hidden this in every live test).
- **One-step launch without TW Mod Manager** (`Launch-Game` in
  `companion/Companion.ps1`, used by the desktop shortcut / Start Pilot.cmd):
  writes `%LOCALAPPDATA%\JawsWarhammer2\nvda_mods.txt` (`add_working_directory
  "<game>/data"; mod "jaws_access.pack";`) and starts `Warhammer2.exe` with it
  and `; -dx11`, the command line TW Mod Manager's Play uses. Says "Starting
  Warhammer with the accessibility mod. The intro movies play first; Escape
  skips them." Needs Steam running and the installed pack; otherwise it falls
  back to Steam and says to tick jaws_access in the Mod Manager. Only the
  accessibility mod is loaded this way. The launch button is "Launch game".
  As before, the game is launched only after NVDA speech is confirmed.
- Player guide and installer messages updated.
- Harness: 383 frontend scenarios (old exact-template expectations changed to
  "allowed on another PC, blocked when it changes between presses"; + other-PC
  main menu, Continue Campaign active/unavailable, Load Campaign, replaced
  element), 53 campaign scenarios (+ player default reading).
- `tools/live/Test-PlayerLaunch.ps1` runs the installed companion's
  Launch-Game alone (speech stubbed) when NVDA is not running.

## Live (0.6.60, player mode: no test lease, real menu keys)

NVDA was not running on this PC. Start Pilot.cmd (the desktop shortcut's
command) correctly refused to launch without speech ("The RPC server is
unavailable"). Test-PlayerLaunch then ran the installed Launch-Game: the game
started as `Warhammer2.exe "...\nvda_mods.txt" ; -dx11`, no TW Mod Manager
window; main menu after ~170 s (intro movies). Evidence:
`work/live-0.6.60-trial`, `work/live-0.6.60-trial-2`.

- Main menu → Down, Down → "Continue Campaign, button, 2 of 22" → Enter →
  "Continue Campaign activated." → the latest autosave loaded → "Campaign map,
  45 items." "Event Messages, heading".
- Relaunch → Down, Enter → "New Campaign activated." → "Select Campaign. The
  Eye of the Vortex, radio button, checked, 1 of 17" → Continue → "Select
  Lord" → Start Campaign (asked first) → ~5 min later (intro movie + flyover)
  "Campaign map, 53 items." "How They Play, heading, 44 of 53" with HUD reading
  already on → Down read the dialog → A → "Accept activated." "Mission
  Issued!, heading". No turn ended; save count unchanged (2).

## Still open

- "Warhammer accessibility ready" is spoken while the intro movies still play
  (~2 minutes before the menu is visible).
- The friend's PC is untested: these checks are tolerant by design, but his
  menu's IDs/paths have not been seen. If anything fails, his
  `native-ui-graphics-preview.log` shows the reason (`activation.player_target`).
- Steam not running falls back to TW Mod Manager.
- Physical keys (Shift+F2/F3, Escape) unverified by automation.
