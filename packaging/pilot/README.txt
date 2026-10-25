WARHAMMER II + JAWS CO-OP PILOT 0.2.4

An experimental integration attempt for a Windows JAWS player and a friend
using the Windows game on Windows or Proton. This is NOT a finished
accessibility release. Windows/JAWS runtime and actual co-op are UNTESTED.
The package has automated Lua, protocol, pack and installer fixture checks.

UPGRADING FROM ANY EARLIER PILOT
Close the game and companion. Run Uninstall.cmd from the OLD installed package
before running this package's Install.cmd. The installer deliberately refuses
to overwrite differing installed files. Your saves and other mods are preserved.
This update avoids Lua tail calls into native UI methods and reports UI scan
failures. This addresses a suspected native binding stack issue; live menu
reading is not yet confirmed.
It captures protected-call results explicitly and rejects invalid UI
return types, fixing the observed child-count scan failure. Both the game
startup speech and companion title identify version 0.2.4. It also fixes
the unsupported disabled-state getter and filters internal
menu containers. Main-menu activation still needs your live test.

INSTALL ON YOUR FRIEND'S WINDOWS PC
1. Install the Steam Windows version of Total War: WARHAMMER II and JAWS.
2. Extract the entire ZIP to a folder. Close the game and any prior companion.
3. Run Install.cmd. It finds a standard Steam installation or asks for the
   folder containing Warhammer2.exe. It also checks other Steam libraries.
   No RPFM, Python, SDK, or third-party launcher is needed.
4. Start JAWS. Open the desktop shortcut "Warhammer JAWS Pilot" or run
   Start Pilot.cmd. The companion should speak a test message, then launch
   the game through Steam. Keep the companion running while playing.
5. In the game's existing launcher, enable jaws_access in Mod Manager.
   Disable jaws_probe. If the pack does not appear, report this before testing.
   The installer does not change mod load order or skip the game launcher.
6. Try a disposable SINGLE-PLAYER campaign and battle first. Then test co-op.

The installer puts the pack in the game's data folder and the companion in
%LOCALAPPDATA%\JawsWarhammer2\App. It creates a desktop shortcut when possible.
If Program Files access is denied, run Install.cmd as administrator using the
same Windows account, or copy jaws_access.pack manually and rerun setup.
Do not elevate with a different account: that account has a different app folder.
Scripts are unsigned. CMD launchers use process-only ExecutionPolicy Bypass;
they do not change system policy. Respect any organization/device restrictions.

FIRST SUCCESS CHECK
You should hear the JAWS test sentence. If not, start JAWS and select Test JAWS
in the companion. In the game press F2: a control should be spoken. If the
companion works but the game is silent, see DIAGNOSTICS below.

GAME SHORTCUTS
F2                 Next item in the current category
F3                 Previous item
F4                 Activate; press F4 AGAIN to confirm (navigation cancels)
Shift+F2           Read focused item's details / tooltip / state
Shift+F3           Browse children of focused UI item
Shift+F4           Return to parent; at root, send normal Escape/back
Ctrl+F2            Cycle category: Controls, Readable text, Game actions;
                   battles also include Local army and Visible enemy reports
Ctrl+F3            Campaign treasury/turn or battle status summary
Ctrl+F4            Repeat last game message

UI controls use a bounded traversal of the visible interface tree. Labels,
ordering and modal behavior are experimental; some controls expose internal
IDs or have no useful text. Browse Readable text for panel contents. Shift+F3
can narrow browsing to a group. Disabled controls are announced and blocked.
The scan caps at 3000 visited nodes / 400 entries; it is not a complete
replacement for every screen. A changed target must be browsed again.

Game actions include opening recruitment/building/research/diplomacy panels,
normal next/previous selection, end turn, battle halt, movement steps,
formation changes, melee/run toggles and ability shortcuts. These send normal
UI inputs; the game retains its rules and decides whether they take effect.
"Input sent" does NOT mean the action succeeded. Read the resulting UI.
F-key events may also reach existing game/mod bindings; test for conflicts.

COMPANION SHORTCUTS (CTRL+ALT)
R                  Repeat speech
S                  Stop speech
M                  Mute / unmute pilot speech
H                  Toggle hover speech (starts OFF)
Arrow keys         Move pointer 40 pixels; location spoken as screen percentages
F                  Toggle 5-pixel fine movement / 40-pixel coarse movement
C                  Center pointer in game window
Space              Left click after releasing modifiers
Enter              Right click after releasing modifiers

Keyboard mouse actions operate only while Warhammer2 is the foreground
process and the cursor is inside its client area. Release Ctrl/Alt within
two seconds to perform a click; changing window focus cancels it. These are
real clicks, with no extra confirmation. Use them to select map objects,
move selected armies/units or attack normal targets. Enable hover speech to
hear text the game exposes under the cursor. A blind player may still need
help finding spatial targets: screen percentages are not a world map, and
icons/battlefield objects may not expose text. This is a rough navigation aid.
Shortcut conflicts are reported. AltGr layouts may conflict with Ctrl+Alt.

BATTLE REPORTS AND CO-OP LIMITS
Reports use the local alliance AND local army index, filter hidden enemies,
and list soldiers, ammunition, melee, routing and under-fire status. Reports
are on demand, not continuous alerts. They do not grant control of units.
Transferred/shared units may only appear in normal UI cards, not the local
army report. Use those cards or normal selection shortcuts to command them.
No scripted unit controller or campaign resource mutation is used.
Unit transfers, multiplayer timing, targeting, and dialog behavior need
real testing. Pause is not required by the design or assumed available.
Accessible lobby setup, every faction-specific panel, braille output and
independent spatial battle play are not verified or guaranteed by this pilot.

YOUR PARTNER ON LINUX
Use the Steam WINDOWS build through Proton, with the same jaws_access.pack
in the data folder and enabled in the launcher. Do NOT install this Windows
companion on the Linux player's machine. Match mod versions/load order.
Run the original game normally. The mod's local speech output is optional.
The native Linux port is not the targeted game build.

DIAGNOSTICS
Companion status window: tells whether JAWS is connected and whether fresh
game messages arrived. Old log history is intentionally skipped at startup;
press F2 after starting the companion if the game was already running.
The Open diagnostic folder button opens %LOCALAPPDATA%\JawsWarhammer2.
Send your friend/developer bridge.jsonl, companion.log and the package's
manifest.json, plus what screen/key failed and both game versions.
If bridge.jsonl is absent, also check jaws_access.jsonl and lua_mod_log.txt
beside Warhammer2.exe. The mod falls back to the game working directory if
LOCALAPPDATA is unavailable; an unusual working directory may need investigation.
Do not send Steam login files or credentials. Logs may contain game UI text.
Speech restarts after selecting Test JAWS. Restart the companion/game if
output was disabled following a file error. Status files are local only.

REMOVE / RECOVER
Close the game and companion. Run Uninstall.cmd. The uninstaller removes
only matching installed files and preserves logs, saves, and other mods.
An earlier matching jaws_probe.pack is backed up as diagnostic-backup.pack
and removed during install to avoid duplicate shortcuts; it is not reenabled.
Different existing pilot packs/files are left untouched; back them up before
trying another version. If install was interrupted, inspect the reported
path; remove only incomplete pilot files before rerunning.

No launcher, JAWS binary, or proprietary game scripts are redistributed.
The package uses the launcher's Steam installation and the locally installed
JAWS COM API. The manifest hashes check consistency, not publisher identity.
